### `smart-app-state` capability

This experimental capabiliity allows apps to persist a small amount of
configuration data to an EHR's FHIR server. Conformance requirements described
below apply only to software that implements support for this capability.
Example use cases include:

* App with no backend storage persists user preferences such as default screens, shortcuts, or color preferences. Such apps can save preferences to the EHR and retrieve them on subsequent launches.

* App maintains encrypted external data sets. Such apps can persist access keys to the EHR and retrieve them on subsequent launches, allowing in-app decryption and display of external data sets.

**Apps SHALL NOT use `smart-app-state` when data being persisted could be managed directly using FHIR domain models.** For example, an app would never persist clinical diagnoses or observations using `smart-app-state`. Such usage is prohibited because the standard FHIR API provides safer and more interoperable mechanisms for clinical data sharing.

**Apps SHALL NOT expect the EHR to use or interpret data stored via `smart-app-state`**  unless specific agreements are made outside the scope of this capability.

### Formal definitions

The narrative documentation below provides formal requirements, usage notes, and examples.

In addition, the following conformance resources can support automated processing in FHIR R4:

* [CapabilityStatement/smart-app-state-server](CapabilityStatement/smart-app-state-server.html)
* [OperationDefinition/smart-app-state-query](OperationDefinition-smart-app-state-query.html)
* [OperationDefinition/smart-app-state-modify](OperationDefinition-smart-app-state-modify.html)
* [StructureDefinition/smart-app-state-basic](StructureDefinition-smart-app-state-basic.html)

### Discovery

EHRs supporting this capability SHALL advertise support by including `"smart-app-state"` in the capabilities array of their FHIR server's `.well-known/smart-configuration` file (see [Conformance](conformance.html)).

EHRs supporting this capability SHALL include the `$smart-app-state-query` and `$smart-app-state-modify`  operations in their FHIR server's CapabilityStatement at `/metadata` by including at least the
following content:

```js
{
  "resourceType": "CapabilityStatement",
  "rest": [{
    "operation": [{
      "name": "smart-app-state-query",
      "definition": "http://hl7.org/fhir/smart-app-launch/OperationDefinition/smart-app-state-query"
    }, {
      "name": "smart-app-state-modify",
      "definition": "http://hl7.org/fhir/smart-app-launch/OperationDefinition/smart-app-state-modify"
    }]
  }]
}
```

### Managing app state (CRUDS)

App State data can include details like encryption keys. EHRs SHALL evaluate storage requirements and MAY store App State data separately from their routine FHIR Resource storage space. 

EHRs SHALL allow at least one `smart-app-state` resource per subject per authorized app. EHRs SHOULD describe applicable limits in their developer documentation.

EHRs SHOULD retain app state data for as long as the originating app remains actively registered with the EHR. EHRs MAY establish additional retention policies in their developer documentation.

#### Modifying app state with `$smart-app-state-modify`

An app can **create, update, or delete** app state via:

* `POST /$smart-app-state-modify`

The request is a FHIR `Basic` resource representing the client-supplied state, and the
response is a `Basic` resource representing the state persisted by the EHR (details below).

##### Create

To create a new state item, an app POSTs a `Basic` resource where:

1. Total resource size as serialized in the JSON POST body SHALL NOT exceed 256KB unless the EHR's documentation establishes a higher limit
2. `Basic.id` SHALL NOT be included
2. `Basic.meta.versionId` SHALL NOT be included
3. `Basic.subject.reference` SHALL be a relative reference to a  Patient, Practitioner, PractitionerRole, RelatedPerson, or Person
5. `Basic.code.coding[]`  SHALL include exactly one app-specified Coding
6. `Basic.extension` MAY include non-complex extensions. Extensions SHALL be limited to the `valueString` type unless the EHR's documentation establishes a broader set of allowed extension types

If the EHR accepts the request, the EHR SHALL persist the submitted resource including:

* the Coding present in `Basic.code.coding`
* all top-level extensions present in the request
* a newly generated server-side unique value in populated in `Basic.id`

If the EHR cannot meet all of these obligations, it SHALL reject the request.

##### Updates

To update app state, an app follows the same process as for creation, except:

1. `Basic.id` SHALL be present, to identify the resource to replace
2. `Basic.meta.versionId` SHALL be populated with the current version id
1. `Basic.subject` and `Basic.code` SHALL NOT change from the previously-persisted values

EHR servers SHALL return a `412 Precondition Failed` response if the
`meta.versionId` does not reflect the most recent version stored in the server,
or if the `Basic.subject` or `Basic.code` does not match previously-persisted
value.

##### Deletes

To delete app state, an app follows the same process as for updates, except:

1. `Basic.extension` SHALL NOT be present (this absence signals a deletion)

After successfully deleting state, an app SHALL NOT submit subsequent requests
to modify the same state by `Basic.id`. Servers SHALL process any subsequent
requests about this `Basic.id` as a failed precondition (see
[Updates](#updates)).


#### Querying app state with `$smart-app-state-query`

An app can query for app state via:

* `GET /$smart-app-state-query?subject={}&code={}`

The EHR SHALL support the following query parameters:

* `?subject` behaves like the `subject` search parameter on `Basic`, restricted to relative references that exactly match `Basic.subject.reference`
* `?code` behaves like the `code` search parameter on `Basic`, restricted to fixed codings that exactly match `Basic.code.coding[0]` (i.e., `${system}` + `|` + `${code}`)

The response is a FHIR Bundle where each entry is a `Basic` resource as persisted by the EHR.

####  Managing Contention in `$smart-app-state-modify`

As described above, servers SHALL treat update and delete requests as conditional, rejecting queries that do not refer to the most recent `Basic.meta.versionId`. To summarize the design:

* Servers populate `Basic.meta.versionId` in all returned resources
* Clients include this value in the `POST` body when updating or deleting via `$smart-app-state-modify`
* Servers return a `412 Precondition Failed` response if the client-supplied value does not reflect the current version

### API Examples

#### Example 1: App-specific User Preferences

The following example `POST` body shows how an app might persist a user's app-specific preferences:


```
POST /$smart-app-state-modify
```
```js
{
  "resourceType": "Basic",
  "subject": {"reference": "Practitioner/123"},
  "code": {
    "coding": [
      // app-specific designation; the EHR does not need to understand
      // the meaning of this concept, but SHALL persist it and MAY
      // use it for access control (e.g., using SMART on FHIR scopes
      // or other controls; see below)
      { 
        "system": "https://myapp.example.org",
        "code": "display-preferences"
      }
    ]
  },
  "extension": [
    // app-managed state; the EHR does not need to understand
    // the meaning of these values, but SHALL persist them
    {
      "url": "https://myapp.example.org/display-preferences-v2.0.1",
      "valueString": "{\"defaultView\":\"problem-list\",\"colorblindMode\":\"D\",\"resultsPerPage\":150}"
    }
  ]
}
```

The API response populates `id` and `meta.versionId`, like:

```js
{
  "resourceType": "Basic",
  "id": "1000",
  "meta": {"versionId": "a"},
  "subject": {"reference": "Practitioner/123"},
  ...<snipped for brevity>
```

To query for these data, an app could invoke the following operation (newlines added for clarity):


    GET /$smart-app-state-query?
      subject=Practitioner/123&
      code=https://myapp.example.org|display-preferences

... which returns a Bundle including the "Example 1" payload.

#### Example 2: Access Keys to an external data set

The following `POST` body shows how an app might persist access keys for an externally managed encrypted data set:

```
POST /$smart-app-state-modify
```
```js
{
  "resourceType": "Basic",
  "subject": {"reference": "Patient/123"},
  "code": {
    "coding": [
      // app-specific designation; the EHR does not need to understand
      // the meaning of this concept, but SHALL persist it and MAY
      // use it for access control (e.g., using SMART on FHIR scopes
      // or other controls; see below)
      { 
        "system": "https://myapp.example.org",
        "code": "encrypted-phr-access-keys"
      }
    ]
  },
  "extension": [
    // app-managed state; the EHR does not need to understand
    // the meaning of these values, but SHALL persist them
    {
      "url": "https://myapp.example.org/encrypted-phr-access-keys",
      "valueString": "eyJhbGciOiJSU0EtT0FFUCIsImVuYyI6IkEyNTZH...<snipped>"
    }
  ]
}
```

The EHR responds with a Basic resource representing the new SMART App State object as it has been persisted.  The API response populates `id` and `meta.versionId`, like:

```js
{
  "resourceType": "Basic",
  "id": "1001",
  "meta": {"versionId": "a"},
  "subject": {"reference": "Practitioner/123"},
  ...<snipped for brevity>
```

#### Example 3: Updating the Access Keys from Example 2

The following `POST` body shows how an app might update persisted access keys for an externally managed encrypted data set, based on the response to Example 2.


```
POST /$smart-app-state-modify
```
```js
{
  "resourceType": "Basic",
  "id": "1001",
  "meta": {"versionId": "a"},
  "subject": {"reference": "Patient/123"},
  "code": {
    "coding": [
      { 
        "system": "https://myapp.example.org",
        "code": "encrypted-phr-access-keys"
      }
    ]
  },
  "extension": [
    {
      "url": "https://myapp.example.org/encrypted-phr-access-keys",
      "valueString": "eyJhbGc<updated value, snipped>"
    }
  ]
}
```

The EHR responds with a Basic resource representing the updated SMART App State object as it has been persisted. The API response includes an updated `meta.versionId`, like:

```js
{
  "resourceType": "Basic",
  "id": "1001",
  "meta": {"versionId": "b"},
  ...<snipped for brevity>
```


#### Example 4: Deleting the Access Keys from Example 3

The following `POST` body shows how an app might delete persisted access keys for an externally managed encrypted data set, based on the response to Example 3.


```
POST /$smart-app-state-modify
```
```js
{
  "resourceType": "Basic",
  "id": "1001",
  "meta": {"versionId": "b"},
  "subject": {"reference": "Patient/123"},
  "code": {
    "coding": [
      { 
        "system": "https://myapp.example.org",
        "code": "encrypted-phr-access-keys"
      }
    ]
  }
}
```

The EHR responds with a `200 OK` or `204 No Content` message to indicate a successful deletion.

### Security and Access controls

Apps SHALL NOT use data from `Extension.valueString` without validating or sanitizing the data first. In other words, app developers need to consider a threat model where App State values have been populated with arbitrary content. (Note that EHRs are expected to simply store and return such data unmodified, without "using" the data.)

The EHR SHALL enforce access controls to ensure that only authorized apps are able to perform the FHIR interactions described above. From the app's perspective, these operations are invoked using a SMART on FHIR access token in an Authorization header.

This means the EHR tracks (e.g., in some internal, implementation-specific format) four sets of `Coding`s representing the SMART App State types (i.e., `Basic.code.coding`) that the app is allowed to
  * query, when the subject is the in-context app user
  * query, when the subject is the in-context patient
  * modify, when the subject is the in-context app user
  * modify, when the subject is the in-context patient

EHRs SHALL only associate `Coding`s with an app if the app is trusted to access those data. These decisions can be made out-of-band during or after the app registration process. A recommended default is to allow apps to register only `Codings` where the `system` matches the app's verified origin. For instance, if the EHR has verified that the app developer manages the origin `https://app.example.org`, the app could be associated with SMART App State types like `https://app.example.org|user-preferences` or `https://app.exmample.org|phr-keys`. If an app requires access to other App State types, these could be reviewed through an out-of-band process. This situation is expected when one developer supplies a patient-facing app and another developer supplies a provider-facing "companion app" that needs to query state written by the patient-facing app.

Where appropriate, the EHR MAY expose these controls using SMART scopes as follows.


#### Granting access at the user level

An app writing user-specific state (e.g., user preferences) or writing patient-specific state on behalf of an authorized user can request SMART scopes like:

    user/$smart-app-state-query
    user/$smart-app-state-modify
    
This scope would allow the app to manage any app state that the user is permitted to manage. Note that without further refinement, this scope could allow an app to see and manage app state from *other apps* in addition to its own. This can be a useful behavior in scenarios where sets of apps have a mutual understanding of certain state values (e.g. a suite of apps offered by a single developer). 

#### Granting access at the patient level

An app writing patient-specific state (e.g., access keys for an externally managed encryted data set) can request a SMART scope like:


    patient/$smart-app-state-query
    patient/$smart-app-state-modify
    
This scope would allow the app to manage any app state that the user is permitted to manage on the in-context patient record. Note that without further refinement, this scope could allow an app to see and manage app state from *other apps* in addition to its own. This can be a useful behavior in scenarios where sets of apps have a mutual understanding of certain state values (e.g., a patient-facing mobile app that creates an encrypted data payload and a provider-facing "companion app" that decrypts and displays the data set within the EHR). 

For the scenario of a patient-facing mobile app that works in tandem with provider-facing "companion app" in the EHR, scopes can be narrowed to better reflect minimum necessary access (note the use of more specific codes):

##### Patient-facing mobile app


    patient/$smart-app-state-query?code=https://myapp.example.org|encrypted-phr-access-keys
    patient/$smart-app-state-modify?code=https://myapp.example.org|encrypted-phr-access-keys

##### Provider-facing "companion app" in the EHR

    patient/$smart-app-state-query?code=https://myapp.example.org|encrypted-phr-access-keys


#### Explaining access controls to end users

In the case of user-facing authorization interactions (e.g., for a patient-facing SMART App), it's important to ensure that such scopes can be explained in plain language. EHRs may need to gather additional information from app developers at registration time with explanations, or may apply additional protections to facilitate access control decisions. For example, an EHR might partition app state management for each patient-facing app, to ensure that no patient-facing app is allowed to read another app's data; and with this sort of limitation in place, app state scopes might not require any specific review or user approval, or might use generic langauge like "store and manage its own data".

### Design Notes

Implementers may wonder why the SMART App State capability uses FHIR Operations
instead of FHIR's built-in FHIR REST API (e.g., using CRUD operations on the
`Basic` resource). During the design and prototype phase, implementers
identified requirements that led us to an Operations-based design:

* Ensure that EHRs can identify App State requests via path-based HTTP request
  evaluation. This allows EHRs to route App State requests to a purpose-built
  underlying service. Such identification is not possible when the only path
  information is `/Basic` (e.g., for `POST /Basic`), since non-App-State CRUD operations
  on `Basic` would use this same path.

* Ensure that App State can be persisted separately from other `Basic`
  resources managed by the EHR. This stems from the fact that App State is
  essentially opaque to the EHR and should not be returned in general-purpose
  queries for `Basic` content (which may be used to surface first-class EHR
  concepts).

* Ensure that requests can be authorized "statically", i.e. based on the
  access token and request content alone, prior to retrieving resources
  from a data store. For example, authorizing a CRUD request like
  `GET /Basic/123` would require retrieving the resource from the data
  store before being able to evaluate its subject and coding against the
  access token context. By including the subject and coding in all query
  and modify requests (and by ensuring these values can never change across
  updates for a given state object), we allow servers to compare these values
  against the context in the supplied access token before retrieving resources
  from a data store.
