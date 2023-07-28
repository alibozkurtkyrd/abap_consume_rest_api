*&---------------------------------------------------------------------*
*& Include          ZAB_CONSUME_API_TEST_TOP
*&---------------------------------------------------------------------*

DATA: lv_url     TYPE STRING.
lv_url = 'https://services.odata.org/TripPinRESTierService/(S(sq13a5pf0uojzgozheadpjwx))/People'.

"emails is stored in array. Thereby, define internal table for them
DATA: TT_EMAIL      TYPE TABLE OF STRING WITH DEFAULT KEY,
      TT_FEATURES   TYPE TABLE OF STRING .

"create type for city
TYPES : BEGIN OF TY_CITY,
          NAME            TYPE STRING,
          COUNTRY_REGION  TYPE STRING,
          REGION          TYPE STRING,
        END OF TY_CITY.

" create type for addres
TYPES: BEGIN OF TY_ADDRESS,
        ADDRESS   TYPE STRING,
        CITY      TYPE TY_CITY,"nested structure
      END OF TY_ADDRESS.

"create table for address
DATA: TT_ADDRESS_INFO  TYPE TABLE OF TY_ADDRESS.

TYPES : BEGIN OF TY_DATA,
          USER_NAME            TYPE STRING,
          FIRST_NAME           TYPE STRING,
          LAST_NAME            TYPE STRING,
          MIDDLE_NAME          TYPE STRING,
          GENDER               TYPE STRING,
          AGE                  TYPE STRING,
          EMAILS               LIKE TT_EMAIL, "use like rather than type
          FAVORIETE_FEATURE    TYPE STRING,
          FEATURES             LIKE TT_FEATURES,
          ADDRESS_INFO         LIKE TT_ADDRESS_INFO,
          HOME_ADDRESS         TYPE STRING,
        END OF TY_DATA.

"define main itab
DATA LT_OUTPUT TYPE TABLE OF TY_DATA.

"define types for second itab
TYPES : BEGIN OF TY_HELPER,
          USER_NAME       TYPE STRING,
          EMAIL           TYPE STRING,
          FEATURE         TYPE STRING,
          ADDRESS         TYPE STRING,
          ADDR_NAME       TYPE STRING,
          COUNTRY_REGION  TYPE STRING,
          REGION          TYPE STRING,
        END OF TY_HELPER.

"lets define the second itab
DATA LT_HELPER TYPE TABLE OF TY_HELPER.
"define structure for helper
DATA GS_HELPER TYPE TY_HELPER.


"define fieldcatalog table and structure
"also define the keyinfo field for common fields of two table
DATA: LT_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV,
      LS_FIELDCAT TYPE SLIS_FIELDCAT_ALV,
      LS_KEYINFO  TYPE SLIS_KEYINFO_ALV.