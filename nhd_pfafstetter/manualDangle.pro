pro manualDangle, segId, strPfaf

; used to manually assign pfaf codes based on segId

; check special case of big basins
case segId of

 ; California

     7917743L: strpfaf = '99299902'  ; 18020001: Goose Lake (California/Oregon)

  948010239LL: strPfaf = '99202'     ; 18010205: Butte, in Klamath

   20296925LL: strPfaf = '992042'    ; 18080001: North Lahonton
  948080332LL: strPfaf = '992044'    ; 18080002: North Lahonton
   20315416LL: strPfaf = '992046'    ; 18080003: North Lahonton

  948100283LL: strPfaf = '98022'     ; 18100100: Southern Mojave. California.
   22599807LL: strPfaf = '980242'    ; 18100204: Salton Sea
   20204804LL: strPfaf = '980244'    ; 18100205: Salton Sea

   20268261LL: strPfaf = '98042'     ; 18090103: Owens Lake 
   ; 1,2,3
   20259695LL: strPfaf = '980442'    ; 18090201: Closed Desert Basins that discharge into South Central California
  948090631LL: strPfaf = '980446'    ; 18090203: Closed Desert Basins that discharge into South Central California
   ; 4,5
  948091000LL: strPfaf = '980462'    ; 18090204: Closed Desert Basins that discharge into South Central California
   ; 6,7,8
   22677316LL: strPfaf = '980482'    ; 18090206: Closed Desert Basins that discharge into South Central California
  948091293LL: strPfaf = '980484'    ; 18090207: Closed Desert Basins that discharge into South Central California

   17657279LL: strPfaf = '98062'     ; 18060003: Upper Central Valley (west of Bakersfield)
   19784451LL: strPfaf = '98064'     ; 18040014: Upper Central Valley (west of Bakersfield)

   17170112LL: strPfaf = '980822'    ; 18030003: Upper Central Valley (west of Bakersfield)
   17165784LL: strPfaf = '980824'    ; 18030004: Upper Central Valley (west of Bakersfield)
   17159214LL: strPfaf = '98084'     ; 18030006: Middle Central Valley (west of Visalia)
   17155414LL: strPfaf = '98086'     ; 18030012: Upper Central Valley

  ; miscellaneous
   20362557LL: strPfaf = '980022'    ;   18070107: Catalina Island
   17590276LL: strPfaf = '980024'    ;   18060014: Santa Cruz Island
   17590276LL: strPfaf = '980026'    ; 1180000368: Drainage south of the Mexico border
    9988311LL: strPfaf = '992042002' ;   18080001: weird dangling reach in the Great Basin
    9988327LL: strPfaf = '992042004' ;   18080001: weird dangling reach in the Great Basin 

 ; Pacific Northwest
   23241390LL: strPfaf = '12493902'  ; Upper Snake
   23232963LL: strPfaf = '12493904'  ; Upper Snake
   23230457LL: strPfaf = '12493906'  ; Upper Snake
   23227722LL: strPfaf = '12493908'  ; Upper Snake
  947120092LL: strPfaf = '124022'    ; 17120001 - Oregon closed basins: Harney-Malheur Lakes
   24017699LL: strPfaf = '124024'    ; 17120004 - Oregon closed basins: Silver
   24026228LL: strPfaf = '12404'     ; 17120005 - Oregon closed basins: Summer Lake
   24035960LL: strPfaf = '124042'    ; 17120006 - Oregon closed basins: Lake Abert
   24044347LL: strPfaf = '124044'    ; 17120007 - Oregon closed basins: Warner Lakes
   24057183LL: strPfaf = '124046'    ; 17120008 - Oregon closed basins: Guano
   24073929LL: strPfaf = '12408'     ; 17120009 - Oregon closed basins: Alvord Lake
   23952728LL: strPfaf = '1422'      ; Chilliwack River, flows into the Fraser
   23952646LL: strPfaf = '1424'      ; Silesia Creek, flows into the Fraser
   23952626LL: strPfaf = '1426'      ; Damfina Creek, flows into the Fraser
   23954059LL: strPfaf = '1402'      ; San Juan Islands

 ; Great Basin

 ; Truckee-Carson
  946050038LL: strPfaf = '90222'     ; 16050103: Pyramid-Winnemucca Lakes. Nevada.
   11323142LL: strPfaf = '90224'     ; 16050104: Granite Springs Valley. Nevada.
   13069184LL: strPfaf = '9024'      ; 16050203: Carson River basin
   10736883LL: strPfaf = '90262'     ; 16050303: The Walker River basin
  946050252LL: strPfaf = '90264'     ; 16050304: Walker Lake

 ; Humboldt
   11160893LL: strPfaf = '9042'      ; 16040108: The Humboldt River Basin, Northern Nevada
   11284660LL: strPfaf = '90442'     ; 16040202: Lower Quinn, NW Nevada
    9985193LL: strPfaf = '90462'     ; 16040204: Massacre Lake. California, Nevada 
  946040234LL: strPfaf = '90464'     ; 16040205: Thousand-Virgin. Nevada, Oregon.

 ; Central Nevada
 ;  --> 1,2,3,4,10
   10719408LL: strPfaf = '90622'     ; 16060001: Dixie Valley. Nevada.
   19887653LL: strPfaf = '90624'     ; 16060002: Gabbs Valley. Nevada.
   19876012LL: strPfaf = '906262'    ; 16060003: Southern Big Smoky Valley. Nevada.
   10694707LL: strPfaf = '906264'    ; 16060004: Northern Big Smoky Valley. Nevada.
   19860136LL: strPfaf = '90628'     ; 16060010: Fish Lake-Soda Spring Valleys. 
 ;  --> 5,6,11,12
  946060015LL: strPfaf = '90642'     ; 16060005: Diamond-Monitor Valleys. Nevada.
  946060194LL: strPfaf = '90644'     ; 16060006: Little Smoky-Newark Valleys. Nevada.
   19833722LL: strPfaf = '90646'     ; 16060011: Ralston-Stone Cabin Valleys. Nevada.
  946060337LL: strPfaf = '90648'     ; 16060012: Hot Creek-Railroad Valleys. Nevada.
 ;  --> 7,8,9
   22823956LL: strPfaf = '90662'     ; 16060007: Long-Ruby Valleys. Nevada.
  165536688LL: strPfaf = '90664'     ; 16060008: Spring-Steptoe Valleys. Nevada.
   11363705LL: strPfaf = '90666'     ; 16060009: Dry Lake Valley. Nevada. 
 ;  --> 13,14,15
   11677813LL: strPfaf = '90682'     ; 16060013: Cactus-Sarcobatus Flats. Nevada.
   19809535LL: strPfaf = '90684'     ; 16060014: Sand Spring-Tikaboo Valleys. Nevada.
  946060039LL: strPfaf = '90686'     ; 16060015: Ivanpah-Pahrump Valleys. California, Nevada. 

  ; Great Salt Lake
     4608830L: strPfaf = '9082'      ; 16010204: The Bear River Basin, NE Utah
    10390202L: strPfaf = '90842'     ; 16020204: The Great Salt Lake (Jordan. Utah.), NE Utah

  ; 16020307, 08, 09, 10
     1174452L: strPfaf = '908442'    ; 16020308: Northern Great Salt Lake Desert.
   946020018L: strPfaf = '908444'    ; 16020309: Curlew Valley. Idaho, Utah..
     7913958L: strPfaf = '908446'    ; 16020310: The Great Salt Lake, NE Utah
  ; 16020304, 05, 06
   946020037L: strPfaf = '908462'    ; 16020304: Rush-Tooele Valleys. Utah.
    10680592L: strPfaf = '908466'    ; 16020306: Southern Great Salt Lake Desert.
  ; 16020301, 02, 03
  946020430LL: strPfaf = '908482'    ; 16020301: Hamlin-Snake Valleys. Nevada, Utah.
   10402153LL: strPfaf = '908484'    ; 16020302: Pine Valley. Utah. 
  946020680LL: strPfaf = '908486'    ; 16020303: Tule Valley. Utah. 

  ; Sevier Lake / Escalante Desert
     1199836L: strPfaf = '90862'     ; 16030009: Sevier Lake, southern Utah
  946030188LL: strPfaf = '90864'     ; 16030006: Escalante Desert. Nevada, Utah 

  ; miscellaneous
    22069018L: strPfaf = '90684002'  ; weird dangling reach in the lower Colorado
    10022312L: strPfaf = '90864002'  ; weird dangling reach in the lower Colorado

 ; Upper Colorado
    18293484L: strPfaf = '9602'      ; Great Divide closed basin. Wyoming.
    18290868L: strPfaf = '9602002'   ; weird dangling reach in the Missouri 
    18293060L: strPfaf = '9602004'   ; weird dangling reach in the Missouri 
    18290928L: strPfaf = '9602006'   ; weird dangling reach in the Missouri 
    18290914L: strPfaf = '9602006'   ; weird dangling reach in the Missouri 

 ; Colorado
    21412883L: strPfaf = '96'         ; Mouth of the Colorado

 ; mid Colorado
    20664952L: strPfaf = '9604'       ; 15010007 -  Hualapai Wash. Arizona.
    14600813L: strPfaf = '9604002'    ; weird dangling reach in the Great Basin
     3175686L: strPfaf = '9685731001' ; dangling reach in the Upper Colorado

 ; Lower Colorado
    21420492L: strPfaf = '963102'     ; 15030105 - Bouse Wash. Arizona.
    21415111L: strPfaf = '963104'     ; 15030104 - Imperial Reservoir. Arizona, California.
    10018420L: strPfaf = '963302'     ; 15030102 - Piute Wash. California
    21410126L: strPfaf = '961202'     ; 15030108 - Yuma Desert. Arizona.

 ; southern Arizona
    15888878L: strPfaf = '9625202'    ; PROBLEM: Santa Cruz -- should be connected
    15842570L: strPfaf = '9608222'    ; 15080101: Sonora - San Simon Wash. Arizona.
    15838510L: strPfaf = '9608224'    ; 15080102: Sonora - Rio Sonoyta. Arizona.
    15837009L: strPfaf = '960824'     ; 15080200: Sonora - Rio De La Concepcion. Arizona.
    20372843L: strPfaf = '9608262'    ; 15080301: Sonora - Whitewater Draw. Arizona.
   945080061L: strPfaf = '9608264'    ; 15080302: Sonora - San Bernardino Valley. Arizona, New Mexico.
   945080058L: strPfaf = '9608266'    ; 15080303: Sonora - Cloverdale. New Mexico.
    24950581L: strPfaf = '96084'      ; 15040003: Animas Valley. Arizona, New Mexico
    17704789L: strPfaf = '96086002'   ; weird dangling reach in the Rio Grande
   945051018L: strPfaf = '96088'      ; 15050201: Willcox Playa. Arizona.  

 ; Rio Grande
  943020181LL: strPfaf = '920222'    ; 13020210: Jornada Del Muerto. New Mexico.
   17763025LL: strPfaf = '920224'    ; 13020208: Plains of San Agustin. New Mexico.
   17715352LL: strPfaf = '920242'    ; 13030201: Playas Lake, New Mexico
   17706191LL: strPfaf = '920244'    ; 13030202: Mimbres. New Mexico.
  943030266LL: strPfaf = '920246'    ; 13030202: Mimbres. New Mexico.
  943030292LL: strPfaf = '920248'    ; 13030103: Jordana Draw. New Mexico.
   20867464LL: strPfaf = '920422'    ; 13050001: Western Estancia. New Mexico.
   20864943LL: strPfaf = '920424'    ; 13050002: Eastern Estancia. New Mexico.
   20849799LL: strPfaf = '920426'    ; 13050003: Tularosa Valley. New Mexico, Texas.
   20832408LL: strPfaf = '920442'    ; 13050004: Salt Basin, New Mexico, Texas.
   20830552LL: strPfaf = '920444'    ; 13050004: Salt Basin, New Mexico, Texas.
   20829490LL: strPfaf = '920446'    ; 13050004: Salt Basin, New Mexico, Texas.

 ; Texas
     5617434L: strPfaf = '916959702' ; Lost Draw (NM/TX)
     1660732L: strPfaf = '9199202'   ; Palo Blanco. Texas.
     1663907L: strPfaf = '9199204'   ; Central Laguna Madre. Texas.


 ; Souris-Red-Rainy
   24748285LL: strPfaf = '422'       ; Waterton Lake,   Glacier National Park
    9302483LL: strPfaf = '424222'    ; Near Belly River,     Glacier National Park
    9302487LL: strPfaf = '424224'    ; Near Belly River,     Glacier National Park
    9302509LL: strPfaf = '42424'     ; Belly River,     Glacier National Park
    9302479LL: strPfaf = '42426'     ; North Fork, Belly River,     Glacier National Park
    9305314LL: strPfaf = '42442'     ; East Fork Lee Creek,     Glacier National Park
    9305316LL: strPfaf = '42444'     ; Middle Fork Lee Creek,     Glacier National Park
    9305366LL: strPfaf = '42446'     ; Lee Creek,     Glacier National Park
    9305362LL: strPfaf = '424482'    ; Jule Creek,     Glacier National Park
    9305360LL: strPfaf = '424484'    ; Unknown,     Glacier National Park
    9305350LL: strPfaf = '4262'      ; St Mary's River, Glacier National Park
    9306062LL: strPfaf = '4264'      ; St Mary's River, Glacier National Park
    9305354LL: strPfaf = '4282'      ; Willow Creek (Milk River?),    Glacier National Park
    9305530LL: strPfaf = '4284'      ; Willow Creek (Milk River?),    Glacier National Park
    9305572LL: strPfaf = '4286'      ; Willow Creek (Milk River?),    Glacier National Park
    9305414LL: strPfaf = '42882'     ; Willow Creek (Milk River?),    Glacier National Park
    9305340LL: strPfaf = '42884'     ; Willow Creek (Milk River?),    Glacier National Park
  939010255LL: strPfaf = '442'       ; Souris
   14412663LL: strPfaf = '444'       ; Pound River
    7077392LL: strPfaf = '462'       ; Red River of the North
    7071682LL: strPfaf = '4642'      ; Joe River
    7088581LL: strPfaf = '4644'      ; Roseau
  167200737LL: strPfaf = '48'        ; Lake of the Woods

 ; Great Lakes
    25293410L: strPfaf = '6922'      ; Grass/Raquette    (flows into St Lawrence, northern NY)
    25371895L: strPfaf = '6924'      ; St Regis River    (flows into St Lawrence, northern NY)
    15450136L: strPfaf = '6926'      ; Pike Creek        (flows into St Lawrence, northern NY)
    15448486L: strPfaf = '6928'      ; Salmon River      (flows into St Lawrence, northern NY)
    15448570L: strPfaf = '6944'      ; Trout River       (flows into St Lawrence, northern NY)
    15448512L: strPfaf = '6948'      ; Chateauguay River (flows into St Lawrence, northern NY)
    25020678L: strPfaf = '696'       ; Richelieu River      (NY/VT-CA border)
    25068048L: strPfaf = '6982'      ; Barton River,        Vermont
   166196261L: strPfaf = '69842'     ; West Holland Pond,   Vermont
     4599299L: strPfaf = '69844'     ; Middle Holland Pond, Vermont
   166196253L: strPfaf = '69846'     ; East Holland Pond,   Vermont
   166196264L: strPfaf = '6986'      ; Coaticook River,     Vermont

 ; Mississippi
    22192508L: strPfaf = '46328602'  ; weird dangling reach with zero area

    21246849L: strPfaf = '82953902'  ; Whitewoman (Colorado/Kansas)

 1100005799LL: strPfaf = '89748402'  ; East fork Poplar River (US/Canada border)

 ; Gulf coast
    6322157LL: strPfaf = '75802'        ; weird dangling reach
    6322161LL: strPfaf = '75804'        ; weird dangling reach
   15702637LL: strPfaf = '79633127702'  ; Louisiana/Mississippi border
   15739357LL: strPfaf = '796352302'    ; Louisiana/Mississippi border

 ; Mid Atlantic
    10466473L: strPfaf = '753316402' ; weird dangling reach near the Delaware Bay

 ; New England
 1010002391LL: strPfaf = '728'       ; St. John River, U.S./Canada border, upstream of Grand Falls
   166195783L: strPfaf = '726'       ; Aroostook River, flows into the St John
      816417L: strPfaf = '72462'     ; Chute River, flows into the St John
      816959L: strPfaf = '72464'     ; Prestile Stream, flows into the St John
      816965L: strPfaf = '72466'     ; Whitney brook, near Prestile Stream, flows into the St John
   931010009L: strPfaf = '7244'      ; North Branch Meduxnekeag River, flows into the St John
      817141L: strPfaf = '7242'      ; South Branch Meduxnekeag River, flows into the St John
      818525L: strPfaf = '7222'      ; Sheean Brook, flows into the St John

 ; Default
 else:      strPfaf = 'unknown'  ; Unknown
endcase

end
