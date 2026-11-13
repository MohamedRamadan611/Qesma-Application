# qesma_api.api.MemberControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**addMember**](MemberControllerApi.md#addmember) | **POST** /api/v1/groups/{gid}/members | 
[**deleteMember**](MemberControllerApi.md#deletemember) | **DELETE** /api/v1/groups/{gid}/members/{mid} | 
[**renameMember**](MemberControllerApi.md#renamemember) | **PATCH** /api/v1/groups/{gid}/members/{mid} | Rename a member, change its role, or remove/reactivate it
[**unlinkMember**](MemberControllerApi.md#unlinkmember) | **POST** /api/v1/groups/{gid}/members/{mid}/unlink | Unlink the account from a member (the member, its history and balance stay)


# **addMember**
> MemberDto addMember(gid, createMemberRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMemberControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final CreateMemberRequest createMemberRequest = ; // CreateMemberRequest | 

try {
    final response = api.addMember(gid, createMemberRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MemberControllerApi->addMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **createMemberRequest** | [**CreateMemberRequest**](CreateMemberRequest.md)|  | 

### Return type

[**MemberDto**](MemberDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteMember**
> deleteMember(gid, mid)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMemberControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String mid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.deleteMember(gid, mid);
} catch on DioException (e) {
    print('Exception when calling MemberControllerApi->deleteMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **mid** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **renameMember**
> MemberDto renameMember(gid, mid, updateMemberRequest)

Rename a member, change its role, or remove/reactivate it

Send at least one of displayName, role, status. displayName: Owner/Admin. role (ADMIN or MEMBER): Owner only. status (LEFT removes a linked member, ACTIVE reactivates): Owner, and Admin for members (not admins). The owner's member is protected (409 OWNER_MEMBER_PROTECTED). A member without an account has no role or status.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMemberControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String mid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final UpdateMemberRequest updateMemberRequest = ; // UpdateMemberRequest | 

try {
    final response = api.renameMember(gid, mid, updateMemberRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling MemberControllerApi->renameMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **mid** | **String**|  | 
 **updateMemberRequest** | [**UpdateMemberRequest**](UpdateMemberRequest.md)|  | 

### Return type

[**MemberDto**](MemberDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **unlinkMember**
> unlinkMember(gid, mid)

Unlink the account from a member (the member, its history and balance stay)

The person loses access to the group at once and the member can be claimed again. The owner's member cannot be unlinked (409 OWNER_MEMBER_PROTECTED); only the owner may unlink an admin.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getMemberControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String mid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.unlinkMember(gid, mid);
} catch on DioException (e) {
    print('Exception when calling MemberControllerApi->unlinkMember: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **mid** | **String**|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

