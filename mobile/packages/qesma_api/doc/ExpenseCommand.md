# qesma_api.model.ExpenseCommand

## Load the model package
```dart
import 'package:qesma_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**adjustmentMinor** | **int** | Integer minor units (piasters: 1 EGP = 100). Never a decimal. | [optional] 
**expenseDate** | [**Date**](Date.md) |  | 
**items** | [**BuiltList&lt;ItemInput&gt;**](ItemInput.md) |  | [optional] 
**participantMemberIds** | **BuiltList&lt;String&gt;** |  | [optional] 
**payers** | [**BuiltList&lt;PayerInput&gt;**](PayerInput.md) |  | [optional] 
**service** | [**ServiceInput**](ServiceInput.md) |  | [optional] 
**shares** | [**BuiltList&lt;ShareInput&gt;**](ShareInput.md) |  | [optional] 
**splitType** | **String** |  | 
**tax** | [**TaxInput**](TaxInput.md) |  | [optional] 
**title** | **String** |  | 
**totalMinor** | **int** | Integer minor units (piasters: 1 EGP = 100). Never a decimal. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


