# qesma_api.api.InviteControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createInvite**](InviteControllerApi.md#createinvite) | **POST** /api/v1/groups/{gid}/invites | Create an invitation (code and link)
[**listInvites**](InviteControllerApi.md#listinvites) | **GET** /api/v1/groups/{gid}/invites | List the group&#39;s invitations, newest first (with their codes)
[**revokeInvite**](InviteControllerApi.md#revokeinvite) | **DELETE** /api/v1/groups/{gid}/invites/{iid} | Revoke an invitation (the code stops working; revoking again is not an error)


# **createInvite**
> InviteView createInvite(gid, idempotencyKey, inviteCommand)

Create an invitation (code and link)

Idempotency-Key (UUID) is required. Defaults: expires in 7 days (1 to 30), unlimited uses (or 1 to 1000), no approval. The code (8 characters, shown XXXX-XXXX) is typed by hand and is also the end of the link.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getInviteControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours.
final InviteCommand inviteCommand = ; // InviteCommand | 

try {
    final response = api.createInvite(gid, idempotencyKey, inviteCommand);
    print(response);
} catch on DioException (e) {
    print('Exception when calling InviteControllerApi->createInvite: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **idempotencyKey** | **String**| Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours. | 
 **inviteCommand** | [**InviteCommand**](InviteCommand.md)|  | [optional] 

### Return type

[**InviteView**](InviteView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listInvites**
> PageResponseInviteView listInvites(gid, page, size)

List the group's invitations, newest first (with their codes)

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getInviteControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final int page = 56; // int | 
final int size = 56; // int | 

try {
    final response = api.listInvites(gid, page, size);
    print(response);
} catch on DioException (e) {
    print('Exception when calling InviteControllerApi->listInvites: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

[**PageResponseInviteView**](PageResponseInviteView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revokeInvite**
> revokeInvite(gid, iid)

Revoke an invitation (the code stops working; revoking again is not an error)

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getInviteControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String iid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.revokeInvite(gid, iid);
} catch on DioException (e) {
    print('Exception when calling InviteControllerApi->revokeInvite: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **iid** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

