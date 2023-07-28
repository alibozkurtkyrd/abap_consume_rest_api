*&---------------------------------------------------------------------*
*& Report ZAB_CONSUME_API_TEST
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZAB_CONSUME_API_TEST.



INCLUDE ZAB_CONSUME_API_TEST_TOP.

START-OF-SELECTION.

"fetch data from API
PERFORM FETCH_API.

IF LT_OUTPUT[] IS NOT INITIAL.
  PERFORM PROCESS_DATA.
  PERFORM DISPLAY_DATA.
ENDIF.
*&---------------------------------------------------------------------*
*& Form FETCH_API
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM FETCH_API .

  "step1 create HTTP Client Object
  cl_http_client=>CREATE_BY_URL(
    exporting
      URL                 = LV_URL  " URL
*      PROXY_HOST         =     " Logical Destination (Specified in Function Call)
*      PROXY_SERVICE      =     " Port Number
*      SSL_ID             =     " SSL Identity
*      SAP_USERNAME       =     " ABAP System, User Logon Name
*      SAP_CLIENT         =     " R/3 System, Client Number from Logon
    importing
      CLIENT              = DATA(LO_HTTP) " HTTP Client Abstraction
    exceptions
      ARGUMENT_NOT_FOUND = 1
      PLUGIN_NOT_ACTIVE  = 2
      INTERNAL_ERROR     = 3
      OTHERS             = 4
  ).
  if sy-subrc = 0.

    "step 2 : Make request
    LO_HTTP->SEND(
      exporting
        TIMEOUT                    = 15    " Timeout of Answer Waiting Time
      exceptions
        HTTP_COMMUNICATION_FAILURE = 1
        HTTP_INVALID_STATE         = 2
        HTTP_PROCESSING_FAILED     = 3
        HTTP_INVALID_TIMEOUT       = 4
        OTHERS                     = 5
    ).
    if sy-subrc <> 0.
*     message id sy-msgid type sy-msgty number sy-msgno
*                with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

    " Step3 Ask for request
    LO_HTTP->RECEIVE(
      exceptions
        HTTP_COMMUNICATION_FAILURE = 1
        HTTP_INVALID_STATE         = 2
        HTTP_PROCESSING_FAILED     = 3
        OTHERS                     = 4
    ).
    if sy-subrc <> 0.
*     message id sy-msgid type sy-msgty number sy-msgno
*                with sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    endif.

   " Step4 : get data

   DATA(RESULT) = LO_HTTP->RESPONSE->GET_CDATA( ).


*   " Step 5 : Display data
*   CL_ABAP_BROWSER=>SHOW_HTML(
*     exporting
*  *     HTML         =     " HTML Table, Line Width 255 Characters
*       TITLE        =  'learn how to parse json'   " Window Title
*  *     SIZE         = CL_ABAP_BROWSER=>MEDIUM    " Size (S,M.L,XL)
*  *     MODAL        = ABAP_TRUE    " Display as Modal Dialog Box
*       HTML_STRING  =  RESULT   " HTML String
*  *     PRINTING     = ABAP_FALSE
*  *     BUTTONS      = NAVIGATE_OFF    " Navigation Keys navigate_...
*  *     FORMAT       = CL_ABAP_BROWSER=>LANDSCAPE    " Landscape/portrait format
*  *     POSITION     = CL_ABAP_BROWSER=>TOPLEFT    " Position
*  *     DATA_TABLE   =     " External data
*  *     ANCHOR       =     " Goto Point
*  *     CONTEXT_MENU = ABAP_FALSE    " Display context menu in browser
*  *     HTML_XSTRING =     " HTML Binary String
*  *     CHECK_HTML   = ABAP_TRUE    " Test of HTML File
*  *     CONTAINER    =
*  *   importing
*  *     HTML_ERRORS  =     " Error List from Test
*   ).

*  --string operation--
  " split data based on bracket('[')
   SPLIT RESULT AT '[' INTO DATA(LV_STRING1) DATA(LV_STRING2).

   "add bracket to left side of string
   LV_STRING2 = |{ '[' && LV_STRING2 }|.

   "remove the close brace('}') by using substring method
   DATA(LV_FINAL_STRING) = SUBSTRING( VAL = LV_STRING2 OFF = 0 LEN = STRLEN( LV_STRING2 ) - 1  ).


    " Step 6 : Deserialize API
    /ui2/cl_json=>DESERIALIZE(
      EXPORTING
        JSON             =  LV_FINAL_STRING  " JSON string
*        JSONX            =                  " JSON XString
        PRETTY_NAME      = /ui2/cl_json=>PRETTY_MODE-CAMEL_CASE                 " Pretty Print property names
*        ASSOC_ARRAYS     =                  " Deserialize associative array as tables with unique keys
*        ASSOC_ARRAYS_OPT =                  " Optimize rendering of name value maps
*        NAME_MAPPINGS    =                  " ABAP<->JSON Name Mapping Table
*        CONVERSION_EXITS =                  " Use DDIC conversion exits on deserialize of values
      CHANGING
        DATA             = LT_OUTPUT                 " Data to serialize
    ).
  endif.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form PROCESS_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM PROCESS_DATA .

  LOOP AT LT_OUTPUT ASSIGNING FIELD-SYMBOL(<FS_OUTPUT>).
    CLEAR GS_HELPER.

    GS_HELPER-USER_NAME = <FS_OUTPUT>-USER_NAME.
    "Iterate over the TT_EMAIL table to get the email address
    LOOP AT <FS_OUTPUT>-EMAILS ASSIGNING FIELD-SYMBOL(<FS_EMAILS>).
      GS_HELPER-EMAIL = <FS_EMAILS>.

      "Iterate over the ADDRESS_INFO table
      LOOP AT <FS_OUTPUT>-ADDRESS_INFO ASSIGNING FIELD-SYMBOL(<FS_ADDRESS_INFO>).
         GS_HELPER-ADDRESS = <FS_ADDRESS_INFO>-ADDRESS.
         GS_HELPER-ADDR_NAME = <FS_ADDRESS_INFO>-CITY-NAME.
         GS_HELPER-COUNTRY_REGION = <FS_ADDRESS_INFO>-CITY-COUNTRY_REGION.
         GS_HELPER-REGION = <FS_ADDRESS_INFO>-CITY-REGION.

         INSERT GS_HELPER INTO TABLE LT_HELPER.
      ENDLOOP.
    ENDLOOP.

*    "Iterate over the TT_FEATURES table to get the field of feature
*    LOOP AT <FS_OUTPUT>-FEATURES ASSIGNING FIELD-SYMBOL(<FS_FAVORITE>).
*      GS_HELPER-FEATURE = <FS_FAVORITE>.
*    ENDLOOP.



  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form DISPLAY_DATA
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM DISPLAY_DATA .

  PERFORM CREATE_FIELDCAT.

  "it is created for change the width size of column
  DATA IS_LAYOUT TYPE SLIS_LAYOUT_ALV.
   IS_LAYOUT-COLWIDTH_OPTIMIZE = 'X'.

  CALL FUNCTION 'REUSE_ALV_HIERSEQ_LIST_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK              = ' '
*     I_CALLBACK_PROGRAM             =
*     I_CALLBACK_PF_STATUS_SET       = ' '
*     I_CALLBACK_USER_COMMAND        = ' '
     IS_LAYOUT                      = IS_LAYOUT
     IT_FIELDCAT                    = LT_FIELDCAT
*     IT_EXCLUDING                   =
*     IT_SPECIAL_GROUPS              =
*     IT_SORT                        =
*     IT_FILTER                      =
*     IS_SEL_HIDE                    =
*     I_SCREEN_START_COLUMN          = 0
*     I_SCREEN_START_LINE            = 0
*     I_SCREEN_END_COLUMN            = 0
*     I_SCREEN_END_LINE              = 0
*     I_DEFAULT                      = 'X'
*     I_SAVE                         = ' '
*     IS_VARIANT                     =
*     IT_EVENTS                      =
*     IT_EVENT_EXIT                  =
      I_TABNAME_HEADER               = 'LT_OUTPUT'
      I_TABNAME_ITEM                 = 'LT_HELPER'
*     I_STRUCTURE_NAME_HEADER        =
*     I_STRUCTURE_NAME_ITEM          =
      IS_KEYINFO                     = LS_KEYINFO
*     IS_PRINT                       =
*     IS_REPREP_ID                   =
*     I_BYPASSING_BUFFER             =
*     I_BUFFER_ACTIVE                =
*     IR_SALV_HIERSEQ_ADAPTER        =
*     IT_EXCEPT_QINFO                =
*     I_SUPPRESS_EMPTY_DATA          = ABAP_FALSE
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER        =
*     ES_EXIT_CAUSED_BY_USER         =
    TABLES
      T_OUTTAB_HEADER                = LT_OUTPUT
      T_OUTTAB_ITEM                  = LT_HELPER
   EXCEPTIONS
     PROGRAM_ERROR                  = 1
     OTHERS                         = 2
            .
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form CREATE_FIELDCAT
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM CREATE_FIELDCAT .

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '1'.
  LS_FIELDCAT-FIELDNAME = 'USER_NAME'.
  LS_FIELDCAT-TABNAME   = 'LT_OUTPUT'.
  LS_FIELDCAT-SELTEXT_L = 'User Name'.
  LS_FIELDCAT-OUTPUTLEN   = '15'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '2'.
  LS_FIELDCAT-FIELDNAME = 'FIRST_NAME'.
  LS_FIELDCAT-TABNAME   = 'LT_OUTPUT'.
  LS_FIELDCAT-SELTEXT_L = 'First Name'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '3'.
  LS_FIELDCAT-FIELDNAME = 'LAST_NAME'.
  LS_FIELDCAT-TABNAME   = 'LT_OUTPUT'.
  LS_FIELDCAT-SELTEXT_L = 'Last Name'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '4'.
  LS_FIELDCAT-FIELDNAME = 'GENDER'.
  LS_FIELDCAT-TABNAME   = 'LT_OUTPUT'.
  LS_FIELDCAT-SELTEXT_L = 'Gender'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '5'.
  LS_FIELDCAT-FIELDNAME = 'AGE'.
  LS_FIELDCAT-TABNAME   = 'LT_OUTPUT'.
  LS_FIELDCAT-SELTEXT_L = 'Age'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '6'.
  LS_FIELDCAT-FIELDNAME = 'FAVORIETE_FEATURE'.
  LS_FIELDCAT-TABNAME   = 'LT_OUTPUT'.
  LS_FIELDCAT-SELTEXT_L = 'Favoriete'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '7'.
  LS_FIELDCAT-FIELDNAME = 'HOME_ADDRESS'.
  LS_FIELDCAT-TABNAME   = 'LT_OUTPUT'.
  LS_FIELDCAT-SELTEXT_L = 'Home Address'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '1'.
  LS_FIELDCAT-FIELDNAME = 'USER_NAME'.
  LS_FIELDCAT-TABNAME   = 'LT_HELPER'.
  LS_FIELDCAT-SELTEXT_L = 'User Name'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '2'.
  LS_FIELDCAT-FIELDNAME = 'EMAIL'.
  LS_FIELDCAT-TABNAME   = 'LT_HELPER'.
  LS_FIELDCAT-SELTEXT_L = 'Email'.
*  LS_FIELDCAT-INTLEN   = 100.
  LS_FIELDCAT-OUTPUTLEN   = '15'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '3'.
  LS_FIELDCAT-FIELDNAME = 'ADDRESS'.
  LS_FIELDCAT-TABNAME   = 'LT_HELPER'.
  LS_FIELDCAT-SELTEXT_L = 'Address'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '4'.
  LS_FIELDCAT-FIELDNAME = 'ADDR_NAME'.
  LS_FIELDCAT-TABNAME   = 'LT_HELPER'.
  LS_FIELDCAT-SELTEXT_L = 'City'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '5'.
  LS_FIELDCAT-FIELDNAME = 'COUNTRY_REGION'.
  LS_FIELDCAT-TABNAME   = 'LT_HELPER'.
  LS_FIELDCAT-SELTEXT_L = 'C Region'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

  CLEAR LS_FIELDCAT.

  LS_FIELDCAT-COL_POS = '6'.
  LS_FIELDCAT-FIELDNAME = 'REGION'.
  LS_FIELDCAT-TABNAME   = 'LT_HELPER'.
  LS_FIELDCAT-SELTEXT_L = 'Region'.
  APPEND LS_FIELDCAT TO LT_FIELDCAT.

*  CLEAR LS_FIELDCAT.

  "field the key info fields
  "common fieds for two itab; LT_HEPER and LT_OUTPUT
  LS_KEYINFO-HEADER01 = 'USER_NAME'.
  LS_KEYINFO-ITEM01   = 'USER_NAME'.

ENDFORM.s