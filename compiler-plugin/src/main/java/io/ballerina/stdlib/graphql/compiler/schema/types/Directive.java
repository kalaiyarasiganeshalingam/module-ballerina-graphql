/*
 * Copyright (c) 2022, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.graphql.compiler.schema.types;

import java.util.ArrayList;
import java.util.List;

/**
 * Represents the {@code __Directive} in GraphQL schema.
 */
public class Directive {
    private final String name;
    private final String description;
    private final List<DirectiveLocation> locations;
    private final List<InputValue> args;

    public Directive(String name, String description) {
        this(name, description, new ArrayList<>());
    }

    public Directive(String name, String description, List<DirectiveLocation> locations) {
        this.name = name;
        this.description = description;
        this.locations = locations;
        this.args = new ArrayList<>();
    }

    public void addLocation(DirectiveLocation directiveLocation) {
        this.locations.add(directiveLocation);
    }

    public void addArg(InputValue inputValue) {
        this.args.add(inputValue);
    }
}
