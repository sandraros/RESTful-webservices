class ZCL_RESOURCE_SCARR definition
  public
  final
  create public .

*"* public components of class ZCL_RESOURCE_SCARR
*"* do not include other source files here!!!
public section.

  interfaces ZIF_RESOURCE_HANDLER .
protected section.
*"* protected components of class ZCL_RESOURCE_SCARR
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_RESOURCE_SCARR
*"* do not include other source files here!!!
ENDCLASS.



CLASS ZCL_RESOURCE_SCARR IMPLEMENTATION.


METHOD ZIF_RESOURCE_HANDLER~handle_get.

  DATA: ls_carr TYPE scarr,
        lt_scarr TYPE TABLE OF scarr,
      lv_carrname TYPE string,
      lv_currcode TYPE string,
      carr_id TYPE string,
      ls_param LIKE LINE OF it_params.
  READ TABLE it_params INTO ls_param INDEX 1.
  carr_id = ls_param-value.

  IF carr_id = '*'.
    SELECT * FROM scarr INTO TABLE lt_scarr.
  ELSE.
    SELECT * FROM scarr INTO TABLE lt_scarr WHERE carrid = carr_id.
  ENDIF.

  IF sy-subrc = 0.
    CALL TRANSFORMATION ('ID')
    SOURCE tab = lt_scarr
    RESULT XML ev_content
    OPTIONS xml_header = 'WITHOUT_ENCODING'.
    ev_status_code = ZIF_RESOURCE_HANDLER~gc_status_ok.
  ELSE.
    ev_status_code = ZIF_RESOURCE_HANDLER~gc_status_gone.
  ENDIF.

ENDMETHOD.
ENDCLASS.
