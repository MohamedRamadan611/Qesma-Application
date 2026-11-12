# qesma_api.api.JoinControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getInvitePreview**](JoinControllerApi.md#getinvitepreview) | **GET** /api/v1/invites/{code} | Look at an invitation before joining
[**joinGroup**](JoinControllerApi.md#joingroup) | **POST** /api/v1/invites/{code}/join | Join the group: claim an existing member or become a new one


# **getInvitePreview**
> InvitePreview getInvitePreview(code)

Look at an invitation before joining

Group name, who invited you, member count and the members nobody has claimed yet. No balances and no accounts. 404 for an unknown code, 410 when expired, used up or revoked.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getJoinControllerApi();
final String code = code_example; // String | 

try {
    final response = api.getInvitePreview(code);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinControllerApi->getInvitePreview: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **code** | **String**|  | 

### Return type

[**InvitePreview**](InvitePreview.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **joinGroup**
> JoinView joinGroup(code, idempotencyKey, joinCommand)

Join the group: claim an existing member or become a new one

Idempotency-Key (UUID) is required. Send exactly one of claimMemberId or newMemberName. 201 JOINED, or 202 PENDING_APPROVAL when an admin must approve first.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getJoinControllerApi();
final String code = code_example; // String | 
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours.
final JoinCommand joinCommand = ; // JoinCommand | 

try {
    final response = api.joinGroup(code, idempotencyKey, joinCommand);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinControllerApi->joinGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **code** | **String**|  | 
 **idempotencyKey** | **String**| Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours. | 
 **joinCommand** | [**JoinCommand**](JoinCommand.md)|  | 

### Return type

[**JoinView**](JoinView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

