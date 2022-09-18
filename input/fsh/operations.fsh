Instance: smart-app-state-query
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/smart-app-launch/OperationDefinition/smart-app-state-query"
* version = "4.0.1"
* name = "SMARTAppStateQuery"
* title = "SMART App State Query"
* status = #active
* kind = #operation
* description = """
    Query a server for stored SMART App State.

    **See [App State capability](./app-state.html) for requirements, usage notes, and examples.**
"""
* code = #smart-app-state
* system = true
* type = false
* instance = false
* parameter[0].name = #subject
* parameter[=].use = #in
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].documentation = "Subject associated with stored SMART App State (see [App State capability](./app-state.html))"
* parameter[=].type = #string
* parameter[=].searchType = #reference
* parameter[+].name = #code
* parameter[=].use = #in
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].documentation = "Code associated with stored SMART App State (see [App State capability](./app-state.html))"
* parameter[=].type = #string
* parameter[=].searchType = #token
* parameter[+].name = #return
* parameter[=].use = #out
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].documentation = "Collection-type Bundle of Basic resources for stored SMART App State (see [App State capability](./app-state.html))"
* parameter[=].type = #Bundle


Instance: smart-app-state-modify
InstanceOf: OperationDefinition
Usage: #definition
* url = "http://hl7.org/fhir/smart-app-launch/OperationDefinition/smart-app-state-modify"
* version = "4.0.1"
* name = "SMARTAppStateModify"
* title = "SMART App State Modify"
* status = #active
* kind = #operation
* description = """
    Modify stored SMART App State.

    **See [App State capability](./app-state.html) for requirements, usage notes, and examples.**
"""

* code = #smart-app-state
* system = true
* type = false
* instance = false
* parameter[0].name = #payload
* parameter[=].use = #in
* parameter[=].min = 1
* parameter[=].max = "1"
* parameter[=].documentation = "Basic resource containing SMART App State to modify (see [App State capability](./app-state.html))"
* parameter[=].type = #Basic
* parameter[+].name = #return
* parameter[=].use = #out
* parameter[=].min = 0
* parameter[=].max = "1"
* parameter[=].documentation = "SMART App State as persisted (absent on deletion) (see [App State capabilitq](./app-state.html))"
* parameter[=].type = #Basic