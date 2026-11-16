# qesma_api.model.VersionConflictProblem

## Load the model package
```dart
import 'package:qesma_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**code** | **String** | Stable machine-readable error code. | 
**detail** | **String** |  | [optional] 
**groups** | [**BuiltList&lt;ProblemGroupsInner&gt;**](ProblemGroupsInner.md) | Only with OWNER_MUST_TRANSFER on DELETE /me: your groups that still depend on you as Owner. | [optional] 
**instance** | **String** |  | [optional] 
**nextAllowedAt** | [**DateTime**](DateTime.md) | Only with REMIND_RATE_LIMITED: the earliest time a reminder for this member may be sent again (UTC). | [optional] 
**requestId** | **String** | Echoes the X-Request-Id response header. | [optional] 
**status** | **int** |  | 
**title** | **String** |  | 
**type** | **String** |  | 
**current** | [**JsonObject**](.md) | The latest state the caller may GET: an ExpenseView (expense operations) or a GroupDto (PATCH group). Absent if it could not be read at the moment of the conflict. | [optional] 
**currentVersion** | **int** | The version now stored; re-send the edit with If-Match set to it to re-apply. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


