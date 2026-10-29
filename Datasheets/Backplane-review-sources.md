# Backplane draft 1 — retrieved datasheets

Retrieved 21 October 2026 for the [schematic review](/home/felix/projects/ashet/home-computer/Hardware/Backplane/Review-Draft1.md). These are original manufacturer documents, sometimes hosted by distributors. Existing datasheets were retained. Downloaded files were checked for PDF format and text extraction; the one remaining parser warning is noted below.

| Saved file | Source | Notes |
| --- | --- | --- |
| [INPAQ-WIP252012S-L-Series.pdf](/home/felix/projects/ashet/home-computer/Datasheets/INPAQ-WIP252012S-L-Series.pdf) | [Download source](https://mm.digikey.com/Volume0/opasdata/d220001/medias/docus/8884/3526_WIP252012S%20L%20Series.pdf) | PDF text extraction succeeded. |
| [JST-SH.pdf](/home/felix/projects/ashet/home-computer/Datasheets/JST-SH.pdf) | [Download source](https://cdn.sparkfun.com/assets/1/9/5/1/8/EM406-SMDConnector-eSH.pdf) | JST SH family catalog including BM03B and BM04B. Manufacturer document hosted by SparkFun; original manufacturer endpoint refused connections. |
| [KEMET-X7R-SMD.pdf](/home/felix/projects/ashet/home-computer/Datasheets/KEMET-X7R-SMD.pdf) | [Download source](https://yageogroup.com/content/datasheet/asset/file/KEM_C1002_X7R_SMD) | PDF text extraction succeeded. |
| [Keystone_3034.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Keystone_3034.pdf) | [Download source](https://beta.keyelco.com/userAssets/file/M60p4-6-7.pdf) | Manufacturer catalog pages including 3034 and its pad dimensions. The current single-part drawing endpoint returned HTTP 403. |
| [Molex-105057-Product-Specification.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Molex-105057-Product-Specification.pdf) | [Download source](https://docs.rs-online.com/6a44/A700000008643305.pdf) | Manufacturer PS-105057-001 product specification from RS. Manufacturer drawing endpoints timed out; no drawing file was saved. |
| [Murata-GRM31CR60J227ME11.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Murata-GRM31CR60J227ME11.pdf) | [Download source](https://www.farnell.com/datasheets/4419190.pdf) | Manufacturer product-search datasheet from Farnell. Poppler reports bad compressed-stream headers in some PDF objects. The first page was rendered and inspected; extracted ratings are readable. Treat graphical/DC-bias coverage as unverified; do not use this copy as an approval specification. |
| [Panasonic-ERA-A-Resistors.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Panasonic-ERA-A-Resistors.pdf) | [Download source](http://industrial.panasonic.com/cdbs/www-data/pdf/RDM0000/AOA0000C307.pdf) | Official Panasonic ERA-A family datasheet. The HTTPS endpoint timed out; HTTP succeeded. Applies to R2902 distributor code P36KDBCT-ND / ERA-3AEB363V (0.1%), despite schematic Value allowing 1%. |
| [Samsung-CL10A106KP8NNNC.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Samsung-CL10A106KP8NNNC.pdf) | [Download source](https://www1.futureelectronics.com/doc/SAMSUNG/CL10A106KP8NNNC.pdf) | Readable manufacturer specification from Future Electronics; replaces a DigiKey-hosted copy whose compressed streams were corrupt. |
| [Samsung-CL10A226MP8NUNC.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Samsung-CL10A226MP8NUNC.pdf) | [Download source](https://mm.digikey.com/Volume0/opasdata/d220001/medias/docus/2901/CL10A226MP8NUNC_Spec.pdf) | PDF text extraction succeeded. |
| [Samsung-CL10C330JB8NNN.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Samsung-CL10C330JB8NNN.pdf) | [Download source](https://datasheet.sic-components.com/CL10C330JB8NNNC_Spec.pdf) | PDF text extraction succeeded. |
| [Susumu-Thick-Film-Resistors.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Susumu-Thick-Film-Resistors.pdf) | [Download source](https://www.susumu.co.jp/common/pdf/n_catalog_partition05_en.pdf) | PDF text extraction succeeded. |
| [Susumu-Thin-Film-Resistors.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Susumu-Thin-Film-Resistors.pdf) | [Download source](https://www.susumu.co.jp/dl/?filename=n_catalog_partition01_en.pdf&type=application/pdf) | PDF text extraction succeeded. |
| [Yageo-RC-Series.pdf](/home/felix/projects/ashet/home-computer/Datasheets/Yageo-RC-Series.pdf) | [Download source](https://yageogroup.com/content/datasheet/asset/file/PYU-RC_GROUP_51_ROHS_L) | PDF text extraction succeeded. |

The core P2, CH32V003, TCA9548A, PCF8523, HC221, oscillator/crystal, FET, PTC and connector documents already present in this directory were also used. The review cites those existing documents directly.

No exact datasheet can be selected for D1001 (“Something Short-Circuit Safe”), the GREEN LED values, Button 12mm, or the generic J2902 power header until a real manufacturer part is chosen. Exact part selection remains a BOM completion task.

Additional reference used to verify numbered Qwiic wiring: [SparkFun Qwiic Mini Human Presence Sensor schematic](https://docs.sparkfun.com/SparkFun_Qwiic_Human_Presence_Sensor-STHS34PF80/assets/board_files/schematic.pdf). USB power context: [TI SLVA049](https://www.ti.com/lit/an/slva049/slva049.pdf).

The pinned platform documents were obtained through the GitHub plugin; local snapshots are under [review-draft1/platform](/home/felix/projects/ashet/home-computer/Hardware/Backplane/review-draft1/platform).

## Second review — 22 October 2026

Added [24LC256.pdf](/home/felix/projects/ashet/home-computer/Datasheets/24LC256.pdf) for the newly fitted U1. Source: [Microchip DS20001203, 24AA256/24LC256/24FC256](https://ww1.microchip.com/downloads/aemDocuments/documents/MPD/ProductDocuments/DataSheets/24AA256-24LC256-24FC256-256K-I2C-Serial-EEPROM-DS20001203.pdf). The 727,562-byte PDF was downloaded from Microchip and text extraction succeeded; the document identifies itself as DS20001203Y. Existing component datasheets were reused.

The updated review, including the corrected P2 supply-range interpretation, is [Review-Round2.md](/home/felix/projects/ashet/home-computer/Hardware/Backplane/Review-Round2.md). Its platform baseline is commit `37b09be1c575f6128992723105f6add68ae32ea6`.
