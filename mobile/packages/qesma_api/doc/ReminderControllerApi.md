# qesma_api.api.ReminderControllerApi

## Load the API package
```dart
import 'package:qesma_api/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**remindTransfer**](ReminderControllerApi.md#remindtransfer) | **POST** /api/v1/groups/{gid}/transfers/remind | Remind a member of a suggested transfer they owe


# **remindTransfer**
> ReminderView remindTransfer(gid, idempotencyKey, remindCommand)

Remind a member of a suggested transfer they owe

Idempotency-Key (UUID) is required. fromMemberId (the debtor) and toMemberId (the creditor) must be a transfer of the current balances. The creditor may remind their own debtor; Owner/Admin may remind for any transfer (403 otherwise). The debtor must be an active member with an account. The amount is the one of the suggested transfer, set by the server. One reminder per debtor per group per 24 hours (any creditor), and a daily cap per sender: 429 REMIND_RATE_LIMITED with nextAllowedAt. A debtor who muted notifications still gets 201 (the mute is never revealed).

### Example
```dart
import 'package:qesma_api/api.dart';

final api = QesmaApi().getReminderControllerApi();
final String gid = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | 
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours.
final RemindCommand remindCommand = {"fromMemberId":"22222222-2222-2222-2222-222222222222","toMemberId":"11111111-1111-1111-1111-111111111111"}; // RemindCommand | 

try {
    final response = api.remindTransfer(gid, idempotencyKey, remindCommand);
    print(response);
} catch on DioException (e) {
    print('Exception when calling ReminderControllerApi->remindTransfer: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **gid** | **String**|  | 
 **idempotencyKey** | **String**| Client-generated UUID, one per create action. Reuse the same key when retrying the SAME action: the stored answer is returned (header Idempotency-Replayed: true). Keys are kept 24 hours. | 
 **remindCommand** | [**RemindCommand**](RemindCommand.md)|  | 

### Return type

[**ReminderView**](ReminderView.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json, application/problem+json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

