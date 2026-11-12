# qesma_api.api.JoinRequestControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**approveJoinRequest**](JoinRequestControllerApi.md#approvejoinrequest) | **POST** /api/v1/groups/{gid}/join-requests/{rid}/approve | Approve a join request: the person becomes a member (or claims the member they chose)
[**listJoinRequests**](JoinRequestControllerApi.md#listjoinrequests) | **GET** /api/v1/groups/{gid}/join-requests | List the requests waiting for a decision, oldest first (the requester by display name only)
[**rejectJoinRequest**](JoinRequestControllerApi.md#rejectjoinrequest) | **POST** /api/v1/groups/{gid}/join-requests/{rid}/reject | Reject a join request


# **approveJoinRequest**
> JoinRequestView approveJoinRequest(gid, rid)

Approve a join request: the person becomes a member (or claims the member they chose)

Repeating the same decision returns the stored result. A member somebody else claimed in the meantime is 409 and the request stays pending so it can be rejected.

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getJoinRequestControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String rid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.approveJoinRequest(gid, rid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinRequestControllerApi->approveJoinRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **rid** | **String**|  | 

### Return type

[**JoinRequestView**](JoinRequestView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listJoinRequests**
> PageResponseJoinRequestView listJoinRequests(gid, page, size)

List the requests waiting for a decision, oldest first (the requester by display name only)

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getJoinRequestControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final int page = 56; // int | 
final int size = 56; // int | 

try {
    final response = api.listJoinRequests(gid, page, size);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinRequestControllerApi->listJoinRequests: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **page** | **int**|  | [optional] [default to 0]
 **size** | **int**|  | [optional] [default to 20]

### Return type

[**PageResponseJoinRequestView**](PageResponseJoinRequestView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rejectJoinRequest**
> JoinRequestView rejectJoinRequest(gid, rid)

Reject a join request

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getJoinRequestControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String rid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 

try {
    final response = api.rejectJoinRequest(gid, rid);
    print(response);
} catch on DioException (e) {
    print('Exception when calling JoinRequestControllerApi->rejectJoinRequest: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **rid** | **String**|  | 

### Return type

[**JoinRequestView**](JoinRequestView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

