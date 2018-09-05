class ZCL_RESTFUL_CONTROLLER definition
  public
  final
  create public .

*"* public components of class ZCL_RESTFUL_CONTROLLER
*"* do not include other source files here!!!
public section.

  interfaces IF_HTTP_EXTENSION .
protected section.
*"* protected components of class ZCL_RESTFUL_CONTROLLER
*"* do not include other source files here!!!

  data GT_ROUTING type Z_RESOURCE_ROUTING_TAB .

  methods GET_ROUTING
    returning
      value(RT_ROUTING_TAB) type Z_RESOURCE_ROUTING_TAB .
  interface ZIF_RESOURCE_HANDLER load .
  methods GET_CONTROLLER
    importing
      !URL_INFO type STRING
    exporting
      !EO_CONTROLLER type ref to ZIF_RESOURCE_HANDLER
      !ET_PARAMS type ZIF_RESOURCE_HANDLER=>TY_T_PARAMS .
private section.
*"* private components of class ZCL_RESTFUL_CONTROLLER
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_RESTFUL_CONTROLLER IMPLEMENTATION.


METHOD get_controller.
  DATA: lt_routing_tab TYPE z_resource_routing_tab,
        result_tab TYPE match_result_tab,
        lv_verif_pattern TYPE string,
        lv_controller_name TYPE seoclsname,
        lv_count TYPE i,
        lt_url_parts TYPE TABLE OF string,
        lv_url_part TYPE string,
        lv_url_info TYPE string,
        lv_signature TYPE string,
        ls_param TYPE ZIF_RESOURCE_HANDLER=>ty_s_params,
        lv_offset TYPE i,
        length TYPE i,
        ls_class TYPE seoclskey.
  CONSTANTS: param_wildcard TYPE string VALUE '([^/])*'.

  FIELD-SYMBOLS: <ls_routing> LIKE LINE OF lt_routing_tab.

  CALL METHOD get_routing
    RECEIVING
      rt_routing_tab = lt_routing_tab.

  LOOP AT lt_routing_tab ASSIGNING <ls_routing>.
*   replace all parameters placeholders by regex
    lv_verif_pattern = <ls_routing>-url_info.
    lv_signature = <ls_routing>-url_info.
    REPLACE ALL OCCURRENCES OF REGEX '\{([A-Z]*[_]*[a-z]*[0-9]*)*\}' IN lv_verif_pattern WITH param_wildcard.
    CONCATENATE '^' lv_verif_pattern '$'  INTO lv_verif_pattern.
*   check if pattern matches current entry
    FIND ALL OCCURRENCES OF REGEX lv_verif_pattern IN url_info MATCH COUNT lv_count.

*   pattern matched
    IF lv_count > 0.
*     get controller class name
      lv_controller_name = <ls_routing>-handler_class.
      ls_class-clsname = lv_controller_name.
*     check if class exists
      CALL FUNCTION 'SEO_CLASS_GET'
        EXPORTING
          clskey                    = ls_class
*         VERSION                   = SEOC_VERSION_INACTIVE
*         STATE                     = '0'
*         NOTE_ASSISTANT_MODE       = SEOX_FALSE
*       IMPORTING
*         SUPERCLASS                =
*         CLASS                     =
       EXCEPTIONS
         not_existing              = 1
         deleted                   = 2
         is_interface              = 3
         model_only                = 4
         OTHERS                    = 5.

*     class found
      IF sy-subrc = 0.
*       create controller
        CREATE OBJECT eo_controller TYPE (lv_controller_name).
*       create parameter table
        SHIFT lv_verif_pattern RIGHT DELETING TRAILING '$'.
        SHIFT lv_verif_pattern LEFT DELETING LEADING ' ^'.

        SPLIT lv_verif_pattern AT param_wildcard INTO TABLE lt_url_parts.
        lv_url_info = url_info.

        LOOP AT lt_url_parts INTO lv_url_part.
          SHIFT lv_signature LEFT DELETING LEADING lv_url_part.
          SHIFT lv_signature LEFT DELETING LEADING '{'.
          SHIFT lv_url_info LEFT DELETING LEADING lv_url_part.

          CLEAR lv_offset.
*       get parameter name
          FIND FIRST OCCURRENCE OF '}' IN lv_signature MATCH OFFSET lv_offset.
          IF lv_offset > 0.
            ls_param-parameter = lv_signature(lv_offset).
            length = STRLEN( lv_signature ).
*         shift offset left deleting leading "}"
            ADD 1 TO lv_offset.
            length = length - lv_offset.
            lv_signature = lv_signature+lv_offset(length).
          ELSE.
*          there has to be an offset for closing characters "}" !!
          ENDIF.

          CLEAR lv_offset.
*       get parameter value
          FIND FIRST OCCURRENCE OF '/' IN lv_url_info MATCH OFFSET lv_offset.
          IF lv_offset > 0.
            ls_param-value = lv_url_info(lv_offset).
            length = STRLEN( lv_url_info ).
            length = length - lv_offset.
            lv_url_info = lv_url_info+lv_offset(length).
          ELSE.
            ls_param-value = lv_url_info.
          ENDIF.

*       append to internal table
          APPEND ls_param TO et_params.

        ENDLOOP.

      ENDIF.

    ENDIF.

  ENDLOOP.

ENDMETHOD.


METHOD get_routing.
  DATA ls_routing LIKE LINE OF rt_routing_tab.

  ls_routing-clnt = sy-mandt.
  ls_routing-guid = '123'.
  ls_routing-url_info = '/scarr/{PARAM_CARR_ID}'.
  ls_routing-handler_class = 'ZCL_RESOURCE_SCARR'.
  APPEND ls_routing TO rt_routing_tab.

  ls_routing-clnt = sy-mandt.
  ls_routing-guid = '456'.
  ls_routing-url_info = '/scarr/{PARAM_CARR_ID}/spfli/{PARAM_CONNID}'.
  ls_routing-handler_class = 'ZCL_RESOURCE_SPFLI'.
  APPEND ls_routing TO rt_routing_tab.

ENDMETHOD.


METHOD if_http_extension~handle_request.
  DATA: url_info TYPE string,
        lv_content TYPE string,
        http_method TYPE string,
        lo_controller TYPE REF TO ZIF_RESOURCE_HANDLER,
        lt_params TYPE ZIF_RESOURCE_HANDLER=>ty_t_params,
        lv_message TYPE xstring,
        lv_body TYPE string,
        lv_status_code TYPE i,
        lv_error_msg TYPE string,
        lv_request_type TYPE string.

* get URL info - will be used for finding matching URL patterns and specified controllers
  url_info = server->request->get_header_field( name = '~PATH_INFO' ).
* get requested content type
  lv_request_type = server->request->get_content_type( ).
* if not specified, initial content type is set to XML
  IF lv_request_type IS INITIAL.
    lv_request_type = ZIF_RESOURCE_HANDLER=>gc_content_type_xml.
  ENDIF.

* get controller for URL
  CALL METHOD get_controller
    EXPORTING
      url_info      = url_info
    IMPORTING
      eo_controller = lo_controller
      et_params     = lt_params.
* decide wether a controller was found or not
  IF lo_controller IS NOT INITIAL.
*   get HTTP request method
    CALL METHOD server->request->get_method
      RECEIVING
        method = http_method.
*   get body of message
    IF http_method NE if_http_request=>co_request_method_get.
      lv_body = server->request->get_cdata( ).
    ENDIF.

*   perform requested method
    CASE http_method.
      WHEN if_http_request=>co_request_method_get.
        CALL METHOD lo_controller->handle_get
          EXPORTING
            it_params       = lt_params
            iv_request_type = lv_request_type
          IMPORTING
            ev_content      = lv_content
            ev_status_code  = lv_status_code
            ev_error_msg    = lv_error_msg.
      WHEN if_http_request=>co_request_method_post.
      WHEN 'DELETE'.
      WHEN 'PUT'.
    ENDCASE.

*   set HTTP status, if not already returned by controller method
    IF lv_status_code IS INITIAL.
      lv_status_code = ZIF_RESOURCE_HANDLER=>gc_status_ok.
    ENDIF.

*   set HTTP status for response including error message, if any
    CALL METHOD server->response->set_status
      EXPORTING
        code   = lv_status_code
        reason = lv_error_msg.

*   set message body
    CALL METHOD server->response->set_cdata( data = lv_content ).
*   set request type
    CALL METHOD server->response->set_content_type( content_type = lv_request_type ).

  ELSE.
*   no controller class found --> set HTTP status "Not found"
    CALL METHOD server->response->set_status
      EXPORTING
        code   = ZIF_RESOURCE_HANDLER=>gc_status_not_found
        reason = 'The resource you specified does not exist.'.
  ENDIF.



ENDMETHOD.
ENDCLASS.
