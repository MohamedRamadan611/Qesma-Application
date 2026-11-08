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
[**renameMember**](MemberControllerApi.md#renamemember) | **PATCH** /api/v1/groups/{gid}/members/{mid} | 


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

