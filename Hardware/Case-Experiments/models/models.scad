


module conn_sub_de_9_fem()
{
    // https://www.traceparts.com/en/product/rs-group-103mm-9-way-90deg-dsub-pcb-socket?CatalogPath=RS_COMPONENTS%3APSF_435849&Product=90-13022024-039027&PartNumber=618009231321
    translate([0,7.5,6.3]) import ("sub-de9-90deg_fem_1216782.stl");
}

module conn_sub_de_9_male()
{
    // https://www.traceparts.com/en/product/rs-group-103mm-9w-header-90deg-dsub-connector?CatalogPath=RS_COMPONENTS%3APSF_435849&Product=90-08022024-066090&PartNumber=618009231421
    translate([0,7.5,6.3]) import("sub-de9-90deg_male_1216780.stl");
}

module conn_sub_de_15_fem()
{
    // https://www.traceparts.com/en/product/rs-group-15w-hd-dsub-ra-pcb-socket?CatalogPath=RS_COMPONENTS%3APSF_435849&Product=90-28022024-026134&PartNumber=A-HDF%2015%20A-KG%2FT
    translate([0,0,6.25]) rotate(90,[1,0,0]) import("sub-de15-90deg_fem_6740971p.stl");
}

module conn_usb_a_2_0_fem()
{
    // https://www.traceparts.com/en/product/rs-components-48258-series-number-right-angle-panel-mount-version-20-type-a-usb-connector-receptacle?CatalogPath=RS_COMPONENTS%3APSF_435862&Product=10-07112019-007195&PartNumber=48258-0001
    translate([0,6.8,3.5]) rotate(90,[1,0,0]) import("usb_a_2_0_fem_48258-0001.stl");
}

module conn_usb_c_fem()
{
    // https://www.traceparts.com/en/product/rs-components-2012670005-female-usb-c-connector-right-angle-surface-mount?CatalogPath=RS_COMPONENTS%3APSF_776935&Product=10-07112019-007157&PartNumber=201267-0005
    translate([-5.4,3.5,-3.2]) rotate(90,[1,0,0]) import("usb_c_fem_201267-0005.stl");
}

module conn_hdmi_fem()
{
    // https://www.traceparts.com/en/product/rs-group-10-hdmi-ra-header-assy-im-type?CatalogPath=RS_COMPONENTS%3APSF_435570&Product=90-13062024-065283&PartNumber=208658-1061
    translate([0,12,7.4]) rotate(90,[1,0,0]) import("hdmi_fem_2010418.stl");
}

module conn_dvi_fem()
{
    // https://www.traceparts.com/en/product/rs-components-female-right-angle-dvi-connector-29-way-3a-40-v-ac?CatalogPath=RS_COMPONENTS%3APSF_435569&Product=10-07112019-008962&PartNumber=74320-1007
    translate([0,0.5,5]) rotate(90,[1,0,0]) import("dvi_fem_74320-1007.stl");
}

module conn_jack_3_5mm_fem()
{
    // https://www.traceparts.com/en/product/rs-group-35mm-jack-socket-pcb4-pole?CatalogPath=RS_COMPONENTS%3APSF_435571&Product=90-09092024-950750&PartNumber=8051665
    translate([0,0,2.4]) rotate(180,[0,0,1]) import("jack_3_5_fem_8051665.stl");
}

module display_oled_128x64_0_96_in()
{
    // https://grabcad.com/library/modeling-oled-screen-128x64-0-91in-by-espacio-maker-1
    translate([0,0,13]) rotate(90,[1,0,0]) import("Tela OLed 128x64 v15.stl");
}

module conn_rj45()
{
    // https://www.traceparts.com/en/product/rs-components-blinded-lightpipe-89?CatalogPath=RS_COMPONENTS%3APSF_435676&Product=10-15082011-086591
     translate([0,7.5,6.4]) rotate(90,[1,0,0]) import("rj45_43860-0016.stl");
}

module conn_cinch_female()
{
    // https://www.sameskydevices.com/product/resource/digikey3dmodel/rcj-041
    rotate(180,[0,0,1]) translate([-5,-10,-3.8]) rotate(90,[0,0,1]) rotate(90,[1,0,0]) import("cinch_rcj-041.stl");
}

module conn_usb_a_2_0_vert_fem()
{
    // https://www.traceparts.com/en/product/rs-components-assmann-wsw-through-hole-type-a-usb-connector-receptacle?CatalogPath=RS_COMPONENTS%3APSF_435862&Product=10-14122010-115825
    translate([0,-0.3,7.5]) rotate(90,[1,0,0]) rotate(90,[0,0,1]) import("usb_a_2_0_fem_vert_a-e.stl");
}

module conn_din_6pin_45322_fem()
{
    // https://www.digikey.de/de/products/detail/te-connectivity-amp-connectors/5212045-1/813421
    translate([0,0,10]) rotate(90,[1,0,0]) import("din_6pin_5212045-1.stl");
}

module conn_pinheader_12x2_90deg_border()
{
    // https://www.digikey.de/de/products/detail/on-shore-technology-inc/302-R241/2794248
    translate([0,8.5,4.5]) rotate(180,[0,0,1]) import("pinheader_12x2_302-R241-56544.stl");
}

module conn_microswitch_2x_vert()
{
    // https://www.digikey.de/de/products/detail/e-switch/TL2243/1794126
    translate([0,4.5,5])  rotate(90,[1,0,0]) rotate(90,[0,0,1]) import("microsw_vert_2x_141_TL2243.stl");
}