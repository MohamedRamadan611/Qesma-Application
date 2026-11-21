# qesma_api.model.Charges

## Load the model package
```dart
import 'package:qesma_api/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**adjustmentMinor** | **int** | Integer minor units (piasters: 1 EGP = 100). Never a decimal. | 
**deliveryMinor** | **int** | Integer minor units (piasters: 1 EGP = 100). Never a decimal. | 
**discount** | [**DiscountCharge**](DiscountCharge.md) |  | [optional] 
**service** | [**ServiceCharge**](ServiceCharge.md) |  | [optional] 
**subtotalMinor** | **int** | Integer minor units (piasters: 1 EGP = 100). Never a decimal. | 
**tax** | [**TaxCharge**](TaxCharge.md) |  | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


