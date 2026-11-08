# qesma_api.api.GroupControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createGroup**](GroupControllerApi.md#creategroup) | **POST** /api/v1/groups | 
[**deleteGroup**](GroupControllerApi.md#deletegroup) | **DELETE** /api/v1/groups/{gid} | 
[**getGroup**](GroupControllerApi.md#getgroup) | **GET** /api/v1/groups/{gid} | 
[**listGroups**](GroupControllerApi.md#listgroups) | **GET** /api/v1/groups | 
[**updateGroup**](GroupControllerApi.md#updategroup) | **PATCH** /api/v1/groups/{gid} | 


# **createGroup**
> GroupDto createGroup(createGroupRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getGroupControllerApi();
final CreateGroupRequest createGroupRequest = ; // CreateGroupRequest | 

try {
    final response = api.createGroup(createGroupRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GroupControllerApi->createGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **createGroupRequest** | [**CreateGroupRequest**](CreateGroupRequest.md)|  | 

### Return type

[**GroupDto**](GroupDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deleteGroup**
> deleteGroup(gid)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getGroupControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    api.deleteGroup(gid);
} catch on DioException (e) {
    print('Exception when calling GroupControllerApi->deleteGroup: $e\n');
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

# **getGroup**
> GroupDto getGroup(gid)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getGroupControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.getGroup(gid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GroupControllerApi->getGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 

### Return type

[**GroupDto**](GroupDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listGroups**
> PageResponseGroupSummaryDto listGroups(page, size)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getGroupControllerApi();
final int page = 56; // int | 
final int size = 56; // int | 

try {
    final response = api.listGroups(page, size);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GroupControllerApi->listGroups: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

[**PageResponseGroupSummaryDto**](PageResponseGroupSummaryDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **updateGroup**
> GroupDto updateGroup(gid, ifMatch, updateGroupRequest)



### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getGroupControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String ifMatch = "1"; // String | The entity version from the last read, as returned in ETag, e.g. \"3\".
final UpdateGroupRequest updateGroupRequest = ; // UpdateGroupRequest | 

try {
    final response = api.updateGroup(gid, ifMatch, updateGroupRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling GroupControllerApi->updateGroup: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **ifMatch** | **String**| The entity version from the last read, as returned in ETag, e.g. \"3\". | 
 **updateGroupRequest** | [**UpdateGroupRequest**](UpdateGroupRequest.md)|  | 

### Return type

[**GroupDto**](GroupDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

