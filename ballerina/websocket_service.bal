// Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/websocket;
import graphql.parser;
import ballerina/lang.value;

isolated service class WsService {
    *websocket:Service;

    private final Engine engine;
    private final readonly & __Schema schema;
    private final Context context;
    
    isolated function init(Engine engine, __Schema schema) {
        self.engine = engine;
        self.schema = schema.cloneReadOnly();
        self.context = new();
    }

    isolated remote function onTextMessage(websocket:Caller caller, string data) returns websocket:Error? {
        lock {
            parser:OperationNode|ErrorDetail node = validateSubscriptionPayload(data, self.engine);
            if node is parser:OperationNode {
                parser:Selection selection = node.getSelections()[0];
                while (selection is parser:FragmentNode) {
                    selection = selection.getSelections()[0];
                } 
                parser:FieldNode fieldNode = <parser:FieldNode> selection;
                stream<any,error?>|error sourceStream = getSubscriptionResponse(self.engine, self.schema, 
                                                                                self.context, fieldNode);                 
                if sourceStream is stream<any,error?>{
                    record{|any value;|}|error? next = sourceStream.iterator().next();
                    while next !is error? {
                        ExecutorVisitor executor = new(self.engine, self.schema, self.context, {}, next.value);
                        OutputObject outputObject = executor.getExecutorResult(node);
                        ResponseFormatter responseFormatter = new(self.schema);
                        OutputObject coercedOutputObject = responseFormatter.getCoercedOutputObject(outputObject, 
                                                                                                    node);
                        if coercedOutputObject.hasKey(DATA_FIELD) || coercedOutputObject.hasKey(ERRORS_FIELD) {
                            check caller->writeTextMessage(coercedOutputObject.toString());
                        }
                        next = sourceStream.iterator().next();
                    }
                } else {
                    check caller->writeTextMessage(sourceStream.toString());
                }                
            } else {
                check caller->writeTextMessage((<ErrorDetail>node).message);
            }
            
        }
    }
}

isolated function validateSubscriptionPayload(string text, Engine engine) returns parser:OperationNode|ErrorDetail {
    json|error payload = value:fromJsonString(text);
    if payload is error {
        return {message: "Invalid Subscription Query"};
    }
    var document = payload.query;
    document = document is error ? payload : document;
    var variables = payload.variables;
    variables = variables is error ? () : variables;
    if document is string && document != "" {
        if variables is map<json> || variables is () {
            parser:OperationNode|OutputObject validationResult = engine.validate(document, getOperationName(payload),
                                                                                 variables);
            if validationResult is parser:OperationNode {
                return validationResult;
            }
            return {message: validationResult.toJsonString()};
        }
        return {message: "Invalid format in request parameter: variables"};
    }
    return {message: "Query not found"};
}

isolated function getSubscriptionResponse(Engine engine, __Schema schema, Context context, 
                                          parser:FieldNode node) returns stream<any,error?>|error {
    ExecutorVisitor executor = new(engine, schema, context, {}, null);
    return <stream<any,error?>|error> getSubscriptionResult(executor, node);
}
