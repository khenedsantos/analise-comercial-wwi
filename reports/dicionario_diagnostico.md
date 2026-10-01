# Dicionário extraído do banco

Descrições são metadados oficiais do backup, não regras inventadas. O relatório interpreta os campos usados.

| Tabela | Coluna | Tipo SQL | Aceita NULL | Descrição da fonte |
| --- | --- | --- | --- | --- |
| Application.Cities | CityID | int | não | Numeric ID used for reference to a city within the database |
| Application.Cities | CityName | nvarchar | não | Formal name of the city |
| Application.Cities | CityName | nvarchar | não | Auto-created to support a foreign key |
| Application.Cities | StateProvinceID | int | não | State or province for this city |
| Application.Cities | Location | geography | sim | Geographic location of the city |
| Application.Cities | LatestRecordedPopulation | bigint | sim | Latest available population for the City |
| Application.Cities | LastEditedBy | int | não |  |
| Application.Cities | ValidFrom | datetime2 | não |  |
| Application.Cities | ValidTo | datetime2 | não |  |
| Application.Countries | CountryID | int | não | Numeric ID used for reference to a country within the database |
| Application.Countries | CountryName | nvarchar | não | Name of the country |
| Application.Countries | FormalName | nvarchar | não | Full formal name of the country as agreed by United Nations |
| Application.Countries | IsoAlpha3Code | nvarchar | sim | 3 letter alphabetic code assigned to the country by ISO |
| Application.Countries | IsoNumericCode | int | sim | Numeric code assigned to the country by ISO |
| Application.Countries | CountryType | nvarchar | sim | Type of country or administrative region |
| Application.Countries | LatestRecordedPopulation | bigint | sim | Latest available population for the country |
| Application.Countries | Continent | nvarchar | não | Name of the continent |
| Application.Countries | Region | nvarchar | não | Name of the region |
| Application.Countries | Subregion | nvarchar | não | Name of the subregion |
| Application.Countries | Border | geography | sim | Geographic border of the country as described by the United Nations |
| Application.Countries | LastEditedBy | int | não |  |
| Application.Countries | ValidFrom | datetime2 | não |  |
| Application.Countries | ValidTo | datetime2 | não |  |
| Application.People | PersonID | int | não | Numeric ID used for reference to a person within the database |
| Application.People | FullName | nvarchar | não | Full name for this person |
| Application.People | FullName | nvarchar | não | Allows quickly locating employees |
| Application.People | PreferredName | nvarchar | não | Allows quickly locating salespeople |
| Application.People | PreferredName | nvarchar | não | Name that this person prefers to be called |
| Application.People | SearchName | nvarchar | não | Name to build full text search on (computed column) |
| Application.People | SearchName | nvarchar | não | Improves performance of name-related queries |
| Application.People | IsPermittedToLogon | bit | não | Improves performance of order picking and invoicing |
| Application.People | IsPermittedToLogon | bit | não | Is this person permitted to log on? |
| Application.People | LogonName | nvarchar | sim | Person's system logon name |
| Application.People | IsExternalLogonProvider | bit | não | Is logon token provided by an external system? |
| Application.People | HashedPassword | varbinary | sim | Hash of password for users without external logon tokens |
| Application.People | IsSystemUser | bit | não | Is the currently permitted to make online access? |
| Application.People | IsEmployee | bit | não | Is this person an employee? |
| Application.People | IsSalesperson | bit | não | Is this person a staff salesperson? |
| Application.People | UserPreferences | nvarchar | sim | User preferences related to the website (holds JSON data) |
| Application.People | PhoneNumber | nvarchar | sim | Phone number |
| Application.People | FaxNumber | nvarchar | sim | Fax number   |
| Application.People | EmailAddress | nvarchar | sim | Email address for this person |
| Application.People | Photo | varbinary | sim | Photo of this person |
| Application.People | CustomFields | nvarchar | sim | Custom fields for employees and salespeople |
| Application.People | OtherLanguages | nvarchar | sim | Other languages spoken (computed column from custom fields) |
| Application.People | LastEditedBy | int | não |  |
| Application.People | ValidFrom | datetime2 | não |  |
| Application.People | ValidTo | datetime2 | não |  |
| Application.StateProvinces | StateProvinceID | int | não | Numeric ID used for reference to a state or province within the database |
| Application.StateProvinces | StateProvinceCode | nvarchar | não | Common code for this state or province (such as WA - Washington for the USA) |
| Application.StateProvinces | StateProvinceName | nvarchar | não | Formal name of the state or province |
| Application.StateProvinces | StateProvinceName | nvarchar | não | Auto-created to support a foreign key |
| Application.StateProvinces | CountryID | int | não | Index used to quickly locate sales territories |
| Application.StateProvinces | CountryID | int | não | Country for this StateProvince |
| Application.StateProvinces | SalesTerritory | nvarchar | não | Sales territory for this StateProvince |
| Application.StateProvinces | Border | geography | sim | Geographic boundary of the state or province |
| Application.StateProvinces | LatestRecordedPopulation | bigint | sim | Latest available population for the StateProvince |
| Application.StateProvinces | LastEditedBy | int | não |  |
| Application.StateProvinces | ValidFrom | datetime2 | não |  |
| Application.StateProvinces | ValidTo | datetime2 | não |  |
| Sales.BuyingGroups | BuyingGroupID | int | não | Numeric ID used for reference to a buying group within the database |
| Sales.BuyingGroups | BuyingGroupName | nvarchar | não | Full name of a buying group that customers can be members of |
| Sales.BuyingGroups | LastEditedBy | int | não |  |
| Sales.BuyingGroups | ValidFrom | datetime2 | não |  |
| Sales.BuyingGroups | ValidTo | datetime2 | não |  |
| Sales.CustomerCategories | CustomerCategoryID | int | não | Numeric ID used for reference to a customer category within the database |
| Sales.CustomerCategories | CustomerCategoryName | nvarchar | não | Full name of the category that customers can be assigned to |
| Sales.CustomerCategories | LastEditedBy | int | não |  |
| Sales.CustomerCategories | ValidFrom | datetime2 | não |  |
| Sales.CustomerCategories | ValidTo | datetime2 | não |  |
| Sales.Customers | CustomerID | int | não | Numeric ID used for reference to a customer within the database |
| Sales.Customers | CustomerName | nvarchar | não | Customer's full name (usually a trading name) |
| Sales.Customers | BillToCustomerID | int | não | Customer that this is billed to (usually the same customer but can be another parent company) |
| Sales.Customers | BillToCustomerID | int | não | Auto-created to support a foreign key |
| Sales.Customers | CustomerCategoryID | int | não | Auto-created to support a foreign key |
| Sales.Customers | CustomerCategoryID | int | não | Customer's category |
| Sales.Customers | BuyingGroupID | int | sim | Customer's buying group (optional) |
| Sales.Customers | BuyingGroupID | int | sim | Auto-created to support a foreign key |
| Sales.Customers | PrimaryContactPersonID | int | não | Auto-created to support a foreign key |
| Sales.Customers | PrimaryContactPersonID | int | não | Primary contact |
| Sales.Customers | AlternateContactPersonID | int | sim | Alternate contact |
| Sales.Customers | AlternateContactPersonID | int | sim | Auto-created to support a foreign key |
| Sales.Customers | DeliveryMethodID | int | não | Auto-created to support a foreign key |
| Sales.Customers | DeliveryMethodID | int | não | Standard delivery method for stock items sent to this customer |
| Sales.Customers | DeliveryCityID | int | não | ID of the delivery city for this address |
| Sales.Customers | DeliveryCityID | int | não | Auto-created to support a foreign key |
| Sales.Customers | PostalCityID | int | não | Improves performance of order picking and invoicing |
| Sales.Customers | PostalCityID | int | não | ID of the postal city for this address |
| Sales.Customers | CreditLimit | decimal(18,2) | sim | Credit limit for this customer (NULL if unlimited) |
| Sales.Customers | AccountOpenedDate | date | não | Date this customer account was opened |
| Sales.Customers | StandardDiscountPercentage | decimal(18,3) | não | Standard discount offered to this customer |
| Sales.Customers | IsStatementSent | bit | não | Is a statement sent to this customer? (Or do they just pay on each invoice?) |
| Sales.Customers | IsOnCreditHold | bit | não | Is this customer on credit hold? (Prevents further deliveries to this customer) |
| Sales.Customers | PaymentDays | int | não | Number of days for payment of an invoice (ie payment terms) |
| Sales.Customers | PhoneNumber | nvarchar | não | Phone number |
| Sales.Customers | FaxNumber | nvarchar | não | Fax number   |
| Sales.Customers | DeliveryRun | nvarchar | sim | Normal delivery run for this customer |
| Sales.Customers | RunPosition | nvarchar | sim | Normal position in the delivery run for this customer |
| Sales.Customers | WebsiteURL | nvarchar | não | URL for the website for this customer |
| Sales.Customers | DeliveryAddressLine1 | nvarchar | não | First delivery address line for the customer |
| Sales.Customers | DeliveryAddressLine2 | nvarchar | sim | Second delivery address line for the customer |
| Sales.Customers | DeliveryPostalCode | nvarchar | não | Delivery postal code for the customer |
| Sales.Customers | DeliveryLocation | geography | sim | Geographic location for the customer's office/warehouse |
| Sales.Customers | PostalAddressLine1 | nvarchar | não | First postal address line for the customer |
| Sales.Customers | PostalAddressLine2 | nvarchar | sim | Second postal address line for the customer |
| Sales.Customers | PostalPostalCode | nvarchar | não | Postal code for the customer when sending by mail |
| Sales.Customers | LastEditedBy | int | não |  |
| Sales.Customers | ValidFrom | datetime2 | não |  |
| Sales.Customers | ValidTo | datetime2 | não |  |
| Sales.CustomerTransactions | CustomerTransactionID | int | não | Numeric ID used to refer to a customer transaction within the database |
| Sales.CustomerTransactions | CustomerID | int | não | Customer for this transaction |
| Sales.CustomerTransactions | CustomerID | int | não | Auto-created to support a foreign key |
| Sales.CustomerTransactions | TransactionTypeID | int | não | Auto-created to support a foreign key |
| Sales.CustomerTransactions | TransactionTypeID | int | não | Type of transaction |
| Sales.CustomerTransactions | InvoiceID | int | sim | ID of an invoice (for transactions associated with an invoice) |
| Sales.CustomerTransactions | InvoiceID | int | sim | Auto-created to support a foreign key |
| Sales.CustomerTransactions | PaymentMethodID | int | sim | Auto-created to support a foreign key |
| Sales.CustomerTransactions | PaymentMethodID | int | sim | ID of a payment method (for transactions involving payments) |
| Sales.CustomerTransactions | TransactionDate | date | não | Date for the transaction |
| Sales.CustomerTransactions | TransactionDate | date | não | Allows quick location of unfinalized transactions |
| Sales.CustomerTransactions | AmountExcludingTax | decimal(18,2) | não | Transaction amount (excluding tax) |
| Sales.CustomerTransactions | TaxAmount | decimal(18,2) | não | Tax amount calculated |
| Sales.CustomerTransactions | TransactionAmount | decimal(18,2) | não | Transaction amount (including tax) |
| Sales.CustomerTransactions | OutstandingBalance | decimal(18,2) | não | Amount still outstanding for this transaction |
| Sales.CustomerTransactions | FinalizationDate | date | sim | Date that this transaction was finalized (if it has been) |
| Sales.CustomerTransactions | IsFinalized | bit | sim | Is this transaction finalized (invoices, credits and payments have been matched) |
| Sales.CustomerTransactions | LastEditedBy | int | não |  |
| Sales.CustomerTransactions | LastEditedWhen | datetime2 | não |  |
| Sales.InvoiceLines | InvoiceLineID | int | não | Numeric ID used for reference to a line on an invoice within the database |
| Sales.InvoiceLines | InvoiceID | int | não | Invoice that this line is associated with |
| Sales.InvoiceLines | InvoiceID | int | não | Auto-created to support a foreign key |
| Sales.InvoiceLines | StockItemID | int | não | Auto-created to support a foreign key |
| Sales.InvoiceLines | StockItemID | int | não | Stock item for this invoice line |
| Sales.InvoiceLines | Description | nvarchar | não | Description of the item supplied (Usually the stock item name but can be overridden) |
| Sales.InvoiceLines | Description | nvarchar | não | Auto-created to support a foreign key |
| Sales.InvoiceLines | PackageTypeID | int | não | Type of package supplied |
| Sales.InvoiceLines | Quantity | int | não | Quantity supplied |
| Sales.InvoiceLines | UnitPrice | decimal(18,2) | sim | Unit price charged |
| Sales.InvoiceLines | TaxRate | decimal(18,3) | não | Tax rate to be applied |
| Sales.InvoiceLines | TaxAmount | decimal(18,2) | não | Tax amount calculated |
| Sales.InvoiceLines | LineProfit | decimal(18,2) | não | Profit made on this line item at current cost price |
| Sales.InvoiceLines | ExtendedPrice | decimal(18,2) | não | Extended line price charged |
| Sales.InvoiceLines | LastEditedBy | int | não |  |
| Sales.InvoiceLines | LastEditedWhen | datetime2 | não |  |
| Sales.Invoices | InvoiceID | int | não | Numeric ID used for reference to an invoice within the database |
| Sales.Invoices | CustomerID | int | não | Customer for this invoice |
| Sales.Invoices | CustomerID | int | não | Auto-created to support a foreign key |
| Sales.Invoices | BillToCustomerID | int | não | Auto-created to support a foreign key |
| Sales.Invoices | BillToCustomerID | int | não | Bill to customer for this invoice (invoices might be billed to a head office) |
| Sales.Invoices | OrderID | int | sim | Sales order (if any) for this invoice |
| Sales.Invoices | OrderID | int | sim | Auto-created to support a foreign key |
| Sales.Invoices | DeliveryMethodID | int | não | Auto-created to support a foreign key |
| Sales.Invoices | DeliveryMethodID | int | não | How these stock items are beign delivered |
| Sales.Invoices | ContactPersonID | int | não | Customer contact for this invoice |
| Sales.Invoices | ContactPersonID | int | não | Auto-created to support a foreign key |
| Sales.Invoices | AccountsPersonID | int | não | Auto-created to support a foreign key |
| Sales.Invoices | AccountsPersonID | int | não | Customer accounts contact for this invoice |
| Sales.Invoices | SalespersonPersonID | int | não | Salesperson for this invoice |
| Sales.Invoices | SalespersonPersonID | int | não | Auto-created to support a foreign key |
| Sales.Invoices | PackedByPersonID | int | não | Auto-created to support a foreign key |
| Sales.Invoices | PackedByPersonID | int | não | Person who packed this shipment (or checked the packing) |
| Sales.Invoices | InvoiceDate | date | não | Date that this invoice was raised |
| Sales.Invoices | InvoiceDate | date | não | Allows quick retrieval of invoices confirmed to have been delivered in a given time period |
| Sales.Invoices | CustomerPurchaseOrderNumber | nvarchar | sim | Purchase Order Number received from customer |
| Sales.Invoices | IsCreditNote | bit | não | Is this a credit note (rather than an invoice) |
| Sales.Invoices | CreditNoteReason | nvarchar | sim | Reason that this credit note needed to be generated (if applicable) |
| Sales.Invoices | Comments | nvarchar | sim | Any comments related to this invoice (sent to customer) |
| Sales.Invoices | DeliveryInstructions | nvarchar | sim | Any comments related to delivery (sent to customer) |
| Sales.Invoices | InternalComments | nvarchar | sim | Any internal comments related to this invoice (not sent to the customer) |
| Sales.Invoices | TotalDryItems | int | não | Total number of dry packages (information for the delivery driver) |
| Sales.Invoices | TotalChillerItems | int | não | Total number of chiller packages (information for the delivery driver) |
| Sales.Invoices | DeliveryRun | nvarchar | sim | Delivery run for this shipment |
| Sales.Invoices | RunPosition | nvarchar | sim | Position in the delivery run for this shipment |
| Sales.Invoices | ReturnedDeliveryData | nvarchar | sim | JSON-structured data returned from delivery devices for deliveries made directly by the organization |
| Sales.Invoices | ConfirmedDeliveryTime | datetime2 | sim | Confirmed delivery date and time promoted from JSON delivery data |
| Sales.Invoices | ConfirmedReceivedBy | nvarchar | sim | Confirmed receiver promoted from JSON delivery data |
| Sales.Invoices | LastEditedBy | int | não |  |
| Sales.Invoices | LastEditedWhen | datetime2 | não |  |
| Sales.OrderLines | OrderLineID | int | não | Numeric ID used for reference to a line on an Order within the database |
| Sales.OrderLines | OrderID | int | não | Order that this line is associated with |
| Sales.OrderLines | OrderID | int | não | Auto-created to support a foreign key |
| Sales.OrderLines | StockItemID | int | não | Auto-created to support a foreign key |
| Sales.OrderLines | StockItemID | int | não | Stock item for this order line (FK not indexed as separate index exists) |
| Sales.OrderLines | Description | nvarchar | não | Description of the item supplied (Usually the stock item name but can be overridden) |
| Sales.OrderLines | Description | nvarchar | não | Allows quick summation of stock item quantites already allocated to uninvoiced orders |
| Sales.OrderLines | PackageTypeID | int | não | Improves performance of order picking and invoicing |
| Sales.OrderLines | PackageTypeID | int | não | Type of package to be supplied |
| Sales.OrderLines | Quantity | int | não | Quantity to be supplied |
| Sales.OrderLines | Quantity | int | não | Improves performance of order picking and invoicing |
| Sales.OrderLines | UnitPrice | decimal(18,2) | sim | Unit price to be charged |
| Sales.OrderLines | TaxRate | decimal(18,3) | não | Tax rate to be applied |
| Sales.OrderLines | PickedQuantity | int | não | Quantity picked from stock |
| Sales.OrderLines | PickingCompletedWhen | datetime2 | sim | When was picking of this line completed? |
| Sales.OrderLines | LastEditedBy | int | não |  |
| Sales.OrderLines | LastEditedWhen | datetime2 | não |  |
| Sales.Orders | OrderID | int | não | Numeric ID used for reference to an order within the database |
| Sales.Orders | CustomerID | int | não | Customer for this order |
| Sales.Orders | CustomerID | int | não | Auto-created to support a foreign key |
| Sales.Orders | SalespersonPersonID | int | não | Auto-created to support a foreign key |
| Sales.Orders | SalespersonPersonID | int | não | Salesperson for this order |
| Sales.Orders | PickedByPersonID | int | sim | Person who picked this shipment |
| Sales.Orders | PickedByPersonID | int | sim | Auto-created to support a foreign key |
| Sales.Orders | ContactPersonID | int | não | Auto-created to support a foreign key |
| Sales.Orders | ContactPersonID | int | não | Customer contact for this order |
| Sales.Orders | BackorderOrderID | int | sim | If this order is a backorder, this column holds the original order number |
| Sales.Orders | OrderDate | date | não | Date that this order was raised |
| Sales.Orders | ExpectedDeliveryDate | date | não | Expected delivery date |
| Sales.Orders | CustomerPurchaseOrderNumber | nvarchar | sim | Purchase Order Number received from customer |
| Sales.Orders | IsUndersupplyBackordered | bit | não | If items cannot be supplied are they backordered? |
| Sales.Orders | Comments | nvarchar | sim | Any comments related to this order (sent to customer) |
| Sales.Orders | DeliveryInstructions | nvarchar | sim | Any comments related to order delivery (sent to customer) |
| Sales.Orders | InternalComments | nvarchar | sim | Any internal comments related to this order (not sent to the customer) |
| Sales.Orders | PickingCompletedWhen | datetime2 | sim | When was picking of the entire order completed? |
| Sales.Orders | LastEditedBy | int | não |  |
| Sales.Orders | LastEditedWhen | datetime2 | não |  |
| Warehouse.PackageTypes | PackageTypeID | int | não | Numeric ID used for reference to a package type within the database |
| Warehouse.PackageTypes | PackageTypeName | nvarchar | não | Full name of package types that stock items can be purchased in or sold in |
| Warehouse.PackageTypes | LastEditedBy | int | não |  |
| Warehouse.PackageTypes | ValidFrom | datetime2 | não |  |
| Warehouse.PackageTypes | ValidTo | datetime2 | não |  |
| Warehouse.StockGroups | StockGroupID | int | não | Numeric ID used for reference to a stock group within the database |
| Warehouse.StockGroups | StockGroupName | nvarchar | não | Full name of groups used to categorize stock items |
| Warehouse.StockGroups | LastEditedBy | int | não |  |
| Warehouse.StockGroups | ValidFrom | datetime2 | não |  |
| Warehouse.StockGroups | ValidTo | datetime2 | não |  |
| Warehouse.StockItemHoldings | StockItemID | int | não | ID of the stock item that this holding relates to (this table holds non-temporal columns for stock) |
| Warehouse.StockItemHoldings | QuantityOnHand | int | não | Quantity currently on hand (if tracked) |
| Warehouse.StockItemHoldings | BinLocation | nvarchar | não | Bin location (ie location of this stock item within the depot) |
| Warehouse.StockItemHoldings | LastStocktakeQuantity | int | não | Quantity at last stocktake (if tracked) |
| Warehouse.StockItemHoldings | LastCostPrice | decimal(18,2) | não | Unit cost price the last time this stock item was purchased |
| Warehouse.StockItemHoldings | ReorderLevel | int | não | Quantity below which reordering should take place |
| Warehouse.StockItemHoldings | TargetStockLevel | int | não | Typical quantity ordered |
| Warehouse.StockItemHoldings | LastEditedBy | int | não |  |
| Warehouse.StockItemHoldings | LastEditedWhen | datetime2 | não |  |
| Warehouse.StockItems | StockItemID | int | não | Numeric ID used for reference to a stock item within the database |
| Warehouse.StockItems | StockItemName | nvarchar | não | Full name of a stock item (but not a full description) |
| Warehouse.StockItems | SupplierID | int | não | Usual supplier for this stock item |
| Warehouse.StockItems | SupplierID | int | não | Auto-created to support a foreign key |
| Warehouse.StockItems | ColorID | int | sim | Auto-created to support a foreign key |
| Warehouse.StockItems | ColorID | int | sim | Color (optional) for this stock item |
| Warehouse.StockItems | UnitPackageID | int | não | Usual package for selling units of this stock item |
| Warehouse.StockItems | UnitPackageID | int | não | Auto-created to support a foreign key |
| Warehouse.StockItems | OuterPackageID | int | não | Auto-created to support a foreign key |
| Warehouse.StockItems | OuterPackageID | int | não | Usual package for selling outers of this stock item (ie cartons, boxes, etc.) |
| Warehouse.StockItems | Brand | nvarchar | sim | Brand for the stock item (if the item is branded) |
| Warehouse.StockItems | Size | nvarchar | sim | Size of this item (eg: 100mm) |
| Warehouse.StockItems | LeadTimeDays | int | não | Number of days typically taken from order to receipt of this stock item |
| Warehouse.StockItems | QuantityPerOuter | int | não | Quantity of the stock item in an outer package |
| Warehouse.StockItems | IsChillerStock | bit | não | Does this stock item need to be in a chiller? |
| Warehouse.StockItems | Barcode | nvarchar | sim | Barcode for this stock item |
| Warehouse.StockItems | TaxRate | decimal(18,3) | não | Tax rate to be applied |
| Warehouse.StockItems | UnitPrice | decimal(18,2) | não | Selling price (ex-tax) for one unit of this product |
| Warehouse.StockItems | RecommendedRetailPrice | decimal(18,2) | sim | Recommended retail price for this stock item |
| Warehouse.StockItems | TypicalWeightPerUnit | decimal(18,3) | não | Typical weight for one unit of this product (packaged) |
| Warehouse.StockItems | MarketingComments | nvarchar | sim | Marketing comments for this stock item (shared outside the organization) |
| Warehouse.StockItems | InternalComments | nvarchar | sim | Internal comments (not exposed outside organization) |
| Warehouse.StockItems | Photo | varbinary | sim | Photo of the product |
| Warehouse.StockItems | CustomFields | nvarchar | sim | Custom fields added by system users |
| Warehouse.StockItems | Tags | nvarchar | sim | Advertising tags associated with this stock item (JSON array retrieved from CustomFields) |
| Warehouse.StockItems | SearchDetails | nvarchar | não | Combination of columns used by full text search |
| Warehouse.StockItems | LastEditedBy | int | não |  |
| Warehouse.StockItems | ValidFrom | datetime2 | não |  |
| Warehouse.StockItems | ValidTo | datetime2 | não |  |
| Warehouse.StockItemStockGroups | StockItemStockGroupID | int | não | Internal reference for this linking row |
| Warehouse.StockItemStockGroups | StockItemID | int | não | Stock item assigned to this stock group (FK indexed via unique constraint) |
| Warehouse.StockItemStockGroups | StockGroupID | int | não | StockGroup assigned to this stock item (FK indexed via unique constraint) |
| Warehouse.StockItemStockGroups | LastEditedBy | int | não |  |
| Warehouse.StockItemStockGroups | LastEditedWhen | datetime2 | não |  |
