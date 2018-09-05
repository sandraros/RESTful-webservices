class ZCL_RESOURCE_SPFLI definition
  public
  final
  create public .

*"* public components of class ZCL_RESOURCE_SPFLI
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



CLASS ZCL_RESOURCE_SPFLI IMPLEMENTATION.


METHOD ZIF_RESOURCE_HANDLER~handle_get.

  DATA: ls_spfli TYPE spfli,
        lt_spfli TYPE TABLE OF spfli,
        lv_string_1 TYPE string,
        lv_string_2 TYPE string,
        lv_string_3 TYPE string,
        lv_string_4 TYPE string,
      spfli_id TYPE string,
      carr_id TYPE string,
      ls_param LIKE LINE OF it_params.

  READ TABLE it_params INTO ls_param INDEX 1.
  carr_id = ls_param-value.
  READ TABLE it_params INTO ls_param INDEX 2.
  spfli_id = ls_param-value.

  ls_spfli-carrid = carr_id.
  IF spfli_id = '*'.
    SELECT * FROM spfli INTO TABLE lt_spfli WHERE carrid = ls_spfli-carrid.
  ELSE.
    ls_spfli-connid = spfli_id.
    SELECT * FROM spfli INTO TABLE lt_spfli WHERE carrid = ls_spfli-carrid AND connid = ls_spfli-connid.
  ENDIF.
  IF sy-subrc = 0.
    CALL TRANSFORMATION ('ID')
    SOURCE tab = lt_spfli
    RESULT XML ev_content
    OPTIONS xml_header = 'WITHOUT_ENCODING'.
    ev_status_code = ZIF_RESOURCE_HANDLER~gc_status_ok.
  ELSE.
    ev_status_code = ZIF_RESOURCE_HANDLER~gc_status_gone.
  ENDIF.
ENDMETHOD.
ENDCLASS.
