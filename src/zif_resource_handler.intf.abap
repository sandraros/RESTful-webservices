interface ZIF_RESOURCE_HANDLER
  public .


  types:
    BEGIN OF ty_s_params,
    parameter TYPE string,
    value TYPE string,
  END OF ty_s_params .
  types:
    ty_t_params TYPE TABLE OF ty_s_params .

  constants GC_STATUS_OK type I value 200 ##NO_TEXT.
  constants GC_STATUS_MOVED_PERMANENTLY type I value 301 ##NO_TEXT.
  constants GC_STATUS_GONE type I value 410 ##NO_TEXT.
  constants GC_STATUS_NO_CONTENT type I value 204 ##NO_TEXT.
  constants GC_STATUS_BAD_REQUEST type I value 400 ##NO_TEXT.
  constants GC_STATUS_NOT_FOUND type I value 401 ##NO_TEXT.
  constants GC_STATUS_UNSUPP_MEDIA_TYPE type I value 415 ##NO_TEXT.
  constants GC_CONTENT_TYPE_XML type STRING value 'text/xml' ##NO_TEXT.

  methods HANDLE_DELETE
    importing
      !IT_PARAMS type TY_T_PARAMS
      !IV_REQUEST_TYPE type STRING default 'text/xml'
      !IV_BODY type STRING optional
    exporting
      !EV_CONTENT type STRING
      !EV_STATUS_CODE type I
      !EV_ERROR_MSG type STRING .
  methods HANDLE_GET
    importing
      !IT_PARAMS type TY_T_PARAMS
      !IV_REQUEST_TYPE type STRING optional
    exporting
      !EV_CONTENT type STRING
      !EV_STATUS_CODE type I
      !EV_ERROR_MSG type STRING .
  methods HANDLE_POST
    importing
      !IT_PARAMS type TY_T_PARAMS
      !IV_REQUEST_TYPE type STRING default 'text/xml'
      !IV_BODY type STRING optional
    exporting
      !EV_CONTENT type STRING
      !EV_STATUS_CODE type I
      !EV_ERROR_MSG type STRING .
  methods HANDLE_PUT
    importing
      !IT_PARAMS type TY_T_PARAMS
      !IV_REQUEST_TYPE type STRING default 'text/xml'
      !IV_BODY type STRING optional
    exporting
      !EV_CONTENT type STRING
      !EV_STATUS_CODE type I
      !EV_ERROR_MSG type STRING .
endinterface.
