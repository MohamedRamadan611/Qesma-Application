# qesma_api.api.MembershipControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**leaveGroup**](MembershipControllerApi.md#leavegroup) | **POST** /api/v1/groups/{gid}/leave | Leave the group
[**transferOwnership**](MembershipControllerApi.md#transferownership) | **POST** /api/v1/groups/{gid}/transfer-ownership | Make another member the owner (the old owner becomes ADMIN)


# **leaveGroup**
> leaveGroup(gid)

Leave the group

The member row, its history and its balance stay; the group disappears from the caller's list and becomes 404 for them. The owner gets 409 OWNER_MUST_TRANSFER.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMembershipControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.leaveGroup(gid);
} catch on DioException (e) {
    print('Exception when calling MembershipControllerApi->leaveGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **transferOwnership**
> transferOwnership(gid, transferOwnershipRequest)

Make another member the owner (the old owner becomes ADMIN)

Owner only. The target must be an ACTIVE member with an account (a member who left is 422 MEMBER_INACTIVE). One transaction.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMembershipControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final TransferOwnershipRequest transferOwnershipRequest = ; // TransferOwnershipRequest | 

try {
    api.transferOwnership(gid, transferOwnershipRequest);
} catch on DioException (e) {
    print('Exception when calling MembershipControllerApi->transferOwnership: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **transferOwnershipRequest** | [**TransferOwnershipRequest**](TransferOwnershipRequest.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

