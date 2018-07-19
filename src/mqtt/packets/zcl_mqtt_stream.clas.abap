class ZCL_MQTT_STREAM definition
  public
  create public .

public section.

  methods ADD_HEX
    importing
      !IV_HEX type XSEQUENCE
    returning
      value(RO_STREAM) type ref to ZCL_MQTT_STREAM .
  methods ADD_PACKET
    importing
      !II_PACKET type ref to ZIF_MQTT_PACKET
      !IO_PAYLOAD type ref to ZCL_MQTT_STREAM optional
      !IV_FLAGS type I default 0
    returning
      value(RO_STREAM) type ref to ZCL_MQTT_STREAM .
  methods ADD_STREAM
    importing
      !IO_STREAM type ref to ZCL_MQTT_STREAM .
  methods ADD_UTF8
    importing
      !IV_STRING type CSEQUENCE
    returning
      value(RO_STREAM) type ref to ZCL_MQTT_STREAM .
  methods CONSTRUCTOR
    importing
      !IV_HEX type XSEQUENCE optional .
  methods EAT_HEX
    importing
      !IV_LENGTH type I
    returning
      value(RV_HEX) type XSTRING .
  methods EAT_PACKET
    returning
      value(RI_PACKET) type ref to ZIF_MQTT_PACKET .
  methods EAT_UTF8
    returning
      value(RV_STRING) type STRING .
  methods GET_HEX
    returning
      value(RV_HEX) type XSTRING .
  methods GET_LENGTH
    returning
      value(RV_LENGTH) type I .
  methods PEEK_HEX
    importing
      !IV_LENGTH type I
    returning
      value(RV_HEX) type XSTRING .
protected section.

  data MV_HEX type XSTRING .
private section.
ENDCLASS.



CLASS ZCL_MQTT_STREAM IMPLEMENTATION.


  METHOD ADD_HEX.

    CONCATENATE mv_hex iv_hex INTO mv_hex IN BYTE MODE.

    ro_stream = me.

  ENDMETHOD.


  METHOD add_packet.

    DATA: lv_byte1 TYPE x,
          lv_byte2 TYPE x.


    lv_byte1 = ii_packet->get_type( ) * 16 + iv_flags.

    add_hex( lv_byte1 ).

    IF io_payload IS SUPPLIED.
      lv_byte2 = io_payload->get_length( ). " todo, handle properly
    ENDIF.

    add_hex( lv_byte2 ).

    IF io_payload IS SUPPLIED.
      add_stream( io_payload ).
    ENDIF.

  ENDMETHOD.


  METHOD ADD_STREAM.

    DATA: lv_hex TYPE xstring.


    lv_hex = io_stream->get_hex( ).

    CONCATENATE mv_hex lv_hex INTO mv_hex IN BYTE MODE.

  ENDMETHOD.


  METHOD ADD_UTF8.

    DATA: lv_str TYPE xstring,
          lv_len TYPE x LENGTH 2.


    DATA(lv_hex) = cl_binary_convert=>string_to_xstring_utf8( iv_string ).

    lv_len = xstrlen( lv_hex ).

    CONCATENATE mv_hex lv_len lv_hex INTO mv_hex IN BYTE MODE.

    ro_stream = me.

  ENDMETHOD.


  METHOD constructor.

    IF iv_hex IS SUPPLIED.
      mv_hex = iv_hex.
    ENDIF.

  ENDMETHOD.


  METHOD EAT_HEX.

    rv_hex = mv_hex(iv_length).

    mv_hex = mv_hex+iv_length.

  ENDMETHOD.


  METHOD eat_packet.

    DATA: lv_int TYPE i.


    lv_int = peek_hex( 1 ) / 16.

    CASE lv_int.
      WHEN zif_mqtt_constants=>gc_packets-connect.
        ri_packet = NEW zcl_mqtt_packet_connect( ).
      WHEN zif_mqtt_constants=>gc_packets-connack.
        ri_packet = NEW zcl_mqtt_packet_connack( ).
      WHEN zif_mqtt_constants=>gc_packets-publish.
        ri_packet = NEW zcl_mqtt_packet_publish( ).
      WHEN zif_mqtt_constants=>gc_packets-puback.
        ri_packet = NEW zcl_mqtt_packet_puback( ).
      WHEN zif_mqtt_constants=>gc_packets-pubrec.
        ri_packet = NEW zcl_mqtt_packet_pubrec( ).
      WHEN zif_mqtt_constants=>gc_packets-pubrel.
        ri_packet = NEW zcl_mqtt_packet_pubrel( ).
      WHEN zif_mqtt_constants=>gc_packets-pubcomp.
        ri_packet = NEW zcl_mqtt_packet_pubcomp( ).
      WHEN zif_mqtt_constants=>gc_packets-subscribe.
        ri_packet = NEW zcl_mqtt_packet_subscribe( ).
      WHEN zif_mqtt_constants=>gc_packets-suback.
        ri_packet = NEW zcl_mqtt_packet_suback( ).
      WHEN zif_mqtt_constants=>gc_packets-unsubscribe.
        ri_packet = NEW zcl_mqtt_packet_unsubscribe( ).
      WHEN zif_mqtt_constants=>gc_packets-unsuback.
        ri_packet = NEW zcl_mqtt_packet_unsuback( ).
      WHEN zif_mqtt_constants=>gc_packets-pingreq.
        ri_packet = NEW zcl_mqtt_packet_pingreq( ).
      WHEN zif_mqtt_constants=>gc_packets-pingresp.
        ri_packet = NEW zcl_mqtt_packet_pingresp( ).
      WHEN zif_mqtt_constants=>gc_packets-disconnect.
        ri_packet = NEW zcl_mqtt_packet_disconnect( ).
      WHEN OTHERS.
* todo, RAISE EXCEPTION
    ENDCASE.

    ri_packet->decode( me ).

  ENDMETHOD.


  METHOD EAT_UTF8.

    DATA: lv_len TYPE x LENGTH 2,
          lv_int TYPE i.


    lv_len = eat_hex( 2 ).
    lv_int = lv_len.

    rv_string = cl_binary_convert=>xstring_utf8_to_string( eat_hex( lv_int ) ).

  ENDMETHOD.


  METHOD GET_HEX.

    rv_hex = mv_hex.

  ENDMETHOD.


  METHOD GET_LENGTH.

    rv_length = xstrlen( mv_hex ).

  ENDMETHOD.


  METHOD peek_hex.

    rv_hex = mv_hex(iv_length).

  ENDMETHOD.
ENDCLASS.