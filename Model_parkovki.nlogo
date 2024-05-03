globals
[
  p-valids         ; Доступные патчи для перемещения (не стена)
  Start            ; Начальный патч
  Final-Cost       ; Конечная стоимость пути, полученная с помощью A*
  AstarX           ; Координаты х и у цели, к которой
  AstarY           ; нужно построить путь

  speedmax
  positions        ;список мест (хранит пары координат)
  tempXcordPlace
  tempYcordPlace
  tempVIP
  deceleration   ;замедление
  acceleration   ;ускорение
  xcord      ;координата клика мыши по Х
  ycord      ;координата клика мыши по У
  TimerFlag
  mouse-clicked?       ;нажата ли мышка? булевая переменная

  Purchasing_Cart      ; список мест для брони, аналог корзины покупок
  ReadyToPay?          ; если невозможно купить бронь, не дает провести этап покупки
  TimeConstCounter
  TimeCounter
  MinParkingTime

  TriesNumber          ; счетчик неуспешных попыток. если будет 72. поиск места остановится с сообщением.
  AllowToCreateAgent?

  hours
  minutes

  turtles-list
  tempType
  tempwho
  tempcolor

  cDefault     ;число тех или иных приехавших машин, счетчики
  cBusiness
  cAmbulance
]
turtles-own [
  speed
  parkS            ;режим агента
  XcordPlace
  YcordPlace
  StepsForParking   ; Константа, нужная для определения "шагов" транспорта
  ParkTimer         ;Время пребывания машины на парковке
  row               ;верхняя или нижняя парковка
  VIP
  TypeOfCompany
]
patches-own
[
  father     ; Предыдущий патч на этом пути
  Cost-path  ; Хранит стоимость пути к текущему патчу
  visited?   ; Был ли путь ранее посещен? То есть,
             ; по крайней мере один путь был рассчитан через этот патч
  active?    ; Является ли патч активным? То есть, мы достигли его, но
             ; мы должны рассматривать его, потому что следующие патчи не были исследованы
  free?
  ParkingNumber
  VIPplace
  booking_status?
  statusBefore      ;отображает статус парковки. Занято/свободно
  chosen?           ;отображает, выбрали ли мы ее для брони
]
to setupStandart
  ca
  set cDefault 0
  set cBusiness 0
  set cAmbulance 0
  set speedmax 0.5
  set turtles-list []
  set-current-plot "Скорость машин"
  set-plot-pen-mode 0 ; Несколько линий на графике
  set-plot-pen-color 10 ; Цвет первой линии
  set TriesNumber 0
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;тест
  set deceleration 0.15
  set acceleration 0.0045
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;тест
  ;set ffd 0
  prepareAstar
  makemap
  reset-ticks
  changetime
end

to ChangeTime
  let extramin 0
  set hours random 23
  if hours != 23 [set extramin 1]
  set minutes random 59 + Extramin
end

to LookingForType
  set tempType "None"
  let random-type random 100
  ifelse hours >= 7 and hours <= 20  ;время день/ночь
  [  ;день
    set minparkingtime 2000
    if random-type >= 0 and random-type <= 36 [set tempType "Default" set cDefault cDefault + 1]   ;обычный приехал
    if random-type >= 37 and random-type <= 96 [set tempType "Business" set cBusiness cBusiness + 1]   ;бизнес приехал
    if random-type >= 97 and random-type <= 100 [set tempType "Ambulance" set cAmbulance cAmbulance + 1]   ;Скорая помощь приехала
  ]
  [  ;ночь
    set minparkingtime 8000
    if random-type >= 0 and random-type <= 69 [set tempType "Default" set cDefault cDefault + 1]   ;обычный приехал
    if random-type >= 70 and random-type <= 79 [set tempType "Business" set cBusiness cBusiness + 1]   ;бизнес приехал
    if random-type >= 80 and random-type <= 100 [set tempType "Ambulance" set cAmbulance cAmbulance + 1]   ;Скорая помощь приехала
  ]
  print temptype
end

to spawn_cars
  LookingForPlace
  LookingForType
  if AllowToCreateAgent? = true [
    create-turtles 1 [
      set parktimer -10
      set parks 0
      set speed 0.5
      set xcor 145
      set ycor 130
      set shape "CarTop"
      set size 9
      set heading 180
      set StepsForParking 0
      set XcordPlace tempXcordPlace
      set YcordPlace tempYcordPlace
      set VIP tempVIP
      set TypeOfCompany tempType
      create-temporary-plot-pen (word "Pen " who)
      set-plot-pen-color random-float 5
      set tempwho who
    ]



set turtles-list lput tempwho turtles-list
  ]
end

to  LookingForPlace
  set AllowToCreateAgent? false
  set tempVIP 0
  let random-VIP random 100
  if random-VIP >= 90 [   ;обратнопропорциональный параметр шанса появления ВИП, при 10 шанс появления 90%, при 90 - 10%
    set tempVIP 1
   show "Вип"
  ]
  ifelse tempVIP = 1 [
    let countVIPplaces count patches with [VIPplace = 1 and free? = true]
    ;show (word "Кол-во Вип мест: " countVIPplaces)
    ifelse countVIPplaces > 0 [
      ask one-of patches with [VIPplace = 1 and free? = true] [
        let pxx pxcor
        let pyy pycor
        choosingplace pxx pyy
      ]
    ]
    [
      gettingcoords ;берем координаты обычного места
    ]
  ]
  [
    gettingcoords ;берем координаты обычного места
  ]
end

to gettingcoords
  let random-pos one-of positions

  ;temp координаты для машины, p координаты для проверки места
  let px item 0 random-pos
  let py item 1 random-pos
  choosingPlace px py
end

to ChoosingPlace [px py]
    ask patch px py
  [

    ifelse free? = true and tempVIP >= VIPplace [
      set tempXcordPlace px
      set tempYcordPlace py
      show (word "Место:"ParkingNumber " свободно")
      ;show (word "Координаты места x:" tempXcordPlace " y:" tempYcordPlace)

      ifelse (tempYcordPlace = 119) or (tempYcordPlace = 76) or (tempYcordPlace = 33)
      [set tempYcordPlace tempYcordPlace - 4]
      [set tempYcordPlace tempYcordPlace + 16]
      set tempXcordPlace tempXcordPlace + 4
      ;      show (word "coords for car px:" tempXcordPlace " py:" tempYcordPlace)
      set TriesNumber 0
      set free? false
      set AllowToCreateAgent? true
    ]
    [
      show (word "Место:"ParkingNumber " занято")
      set TriesNumber TriesNumber + 1
      if TriesNumber >= 73 [
        user-message "Нет свободных мест"
        ;        set TriesNumber 0
        set AllowToCreateAgent? false
        stop
      ]
      LookingForPlace
    ]

  ]
end

to goStandart
  ;show turtles-list
  ask turtles with [size = 9 ][
    moving

    get-trafic
  ]
  ;LookingForPlace
   if ticks mod 35 = 0 [
    set minutes minutes + 1
    if minutes = 60 [
      set minutes 0
      set hours hours + 1
    ]
    if hours = 24 [
      set hours 0
    ]
  ]

  tick
end


to get-trafic
  foreach turtles-list [
    n ->
    set-current-plot-pen (word "Pen " n)
    set-plot-pen-color [color] of turtle n
    plotxy (ticks) ([speed] of turtle n)
  ]
end

to moving
  ; чтобы замедлиться когда заезжаешь на парковочное место



  if parks != 2
  and parks != 3
  and parks != 4
  [
    speed-control
    separate-cars
  ]

;0 - главная дорога, 1 - побочная влево, 2 - к месту, 3 парковка, 4 - к главной, 5 - на выход


  if parkS = 0  [
    if YcordPlace >= 102 and YcordPlace <= 119 [

      if ycor - 1.5 <= 114 [set heading -67.5 - 90]
      if ycor - 1 <= 114 [set heading -45 - 90]
      if ycor - 0.5 <= 114 [set heading -22.5 - 90]

      if (ycor >= 113 and ycor <= 114)
      [
      ;  set parks    ;new 1
        ifelse (xcor >= XcordPlace + 0.5) ;and (xcor >= XcordPlace + 0.5)
        [set heading -90]  ;Поворот Влево
        [set heading 90]   ;Поворот Вправо
      ]
      if (xcor <= XcordPlace + 0.5 ) and (xcor >= XcordPlace - 0.5) [
        if 111 < YcordPlace [set heading 0 set parkS 2 set stepsforparking 9.5 set row "Up" set speed 0.5]
        if 111 > YcordPlace [set heading 180 set parkS 2 set stepsforparking 16 set row "Down" set speed 0.5]
      ]
    ]

    if YcordPlace >= 59 and YcordPlace <= 76 [

      if ycor - 1.5 <= 71 [set heading -67.5 - 90]
      if ycor - 1 <= 71 [set heading -45 - 90]
      if ycor - 0.5 <= 71 [set heading -22.5 - 90]

      if(ycor >= 70 and ycor <= 71)
      [        ;set parks    ;new 1
       ifelse (xcor  >= XcordPlace + 0.5) ;;and (xcor - 0.5 <= XcordPlace)
        [set heading -90]  ;Поворот Влево
        [set heading 90]   ;Поворот Вправо
      ]
      if (xcor <= XcordPlace + 0.5 ) and (xcor >= XcordPlace - 0.5) [
        if 68 < YcordPlace [set heading 0 set parkS 2 set stepsforparking 9.5 set row "Up" set speed 0.5]
        if 68 > YcordPlace [set heading 180 set parkS 2 set stepsforparking 16 set row "Down" set speed 0.5]
      ]
    ]
    if YcordPlace >= 16 and YcordPlace <= 33 [

      if ycor - 1.5 <= 28 [set heading -67.5 - 90]
      if ycor - 1 <= 28 [set heading -45 - 90]
      if ycor - 0.5 <= 28 [set heading -22.5 - 90]

      if (ycor >= 27 and ycor <= 28)
      [        ;set parks    ;new 1
       ifelse (xcor >= XcordPlace + 0.5 ) ;;and (xcor - 0.5 <= XcordPlace)
        [set heading -90]  ;Поворот Влево
        [set heading 90]   ;Поворот Вправо
      ]
      if (xcor <= XcordPlace + 0.5 ) and (xcor >= XcordPlace - 0.5) [
        if 24 < YcordPlace [set heading 0 set parkS 2 set stepsforparking 9.5 set row "Up" set speed 0.5]   ;паркуется по направлению в верх
        if 24 > YcordPlace [set heading 180 set parkS 2 set stepsforparking 16 set row "Down" set speed 0.5] ;паркуется по направлению вниз
      ]
    ]
  ]


  if parkS = 2 [
    ;forward speed
    set stepsforparking stepsforparking - 0.5
    if stepsforparking <= 0 [
      set speed speed - 0.05

      if speed <= 0 [
        let randTime random 2000
        set ParkTimer randTime + MinParkingTime
       ; show ParkTimer
        set parks 3
      ]
    ]
  ]

  if parks = 3 [

    ;show parktimer
    set ParkTimer ParkTimer - 1
    if parktimer <= 0 [
      set parktimer 0
      set heading heading + 180
      set parks 4
      if row = "Up" [
        set stepsforparking 21
      ]
      if row = "Down" [
        set stepsforparking 13.5
      ]
    ]
  ]

if parks = 4 [
    set stepsforparking stepsforparking - 0.5
    set speed speed + 0.05
    ;if ycor = 107 or ycor = 64 or ycor = 21 [
    if stepsforparking <= 0 [
      set heading  90


      ifelse row = "Up" [                                          ;машины, парковавшиеся "сверху"

        let tempx XcordPlace - 4
        let tempy YcordPlace + 4
                                                                   ;print (word "Освобождаю место " tempx " " tempy)
        ask patch  tempx tempy [
          if free? = false [
            set free? true                                         ; логически освобождаем место для других машин
                                                                   ;show (word "Место " parkingnumber " освободилось")
          ]
        ]
      ]

      [
        let tempx XcordPlace - 4
        let tempy YcordPlace - 16
                                                                   ;print (word "Освобождаю место " tempx " " tempy)
        ask patch  tempx tempy [
          if free? = false [
            set free? true
                                                                   ;show (word "Место " parkingnumber " освободилось")
          ]
        ]

      ]
      set parks 5
    ]
  ]

  if parks = 5 [
    if xcor + 1.5 >= 153 [set heading 67.5]
    if xcor + 1 >= 153 [set heading 45]
    if xcor + 0.5 >= 153 [set heading 22.5]

    if xcor >= 153[
      set heading 0
    ]
  ]
  if xcor >= 151 and xcor <= 155 and ycor >= 129 and ycor <= 131 [

    set turtles-list remove who turtles-list
    die
  ] ;Выход с парковки
  if speed >= speedmax [set speed speedmax]
  if speed <= 0 [set speed 0]


  fd speed
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;тест
;;;;;;;;;;;;;;;;;;;;;;;;;;;тест

 to separate-cars
  if any? other turtles-here
  [
  fd 1
    separate-cars
  ]
end

to slow-down-car
  set speed speed - deceleration
end

to speed-up-car
  set speed speed + acceleration

end


to speed-control
;  ask patches in-cone 13 60 [set pcolor white]
;  ask patches in-cone 13 45 [set pcolor yellow]
  ifelse any? other turtles in-cone 13 60  [
    ;let car-ahead one-of turtles in-cone 3 3
    ;ifelse car-ahead != nobody
    ;set speed [speed] of car-ahead
    slow-down-car
  ]
  [
    speed-up-car
  ]

  if speed < 0
  [
    set speed 0
  ]

  if speed > speedmax
  [
    set speed speedmax
  ]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;тест
;;;;;;;;;;;;;;;;;;;;;;;;;;;тест

to redd
  ask patches [
    if pxcor = 145 and pycor >= 28 and pycor <= 130  [set pcolor red + 1]
    if pxcor >= 8 and pxcor <= 144 and pycor = 114  [set pcolor red + 1]
    if pxcor = 8 and pycor >= 103 and pycor <= 118   [set pcolor red + 1]
    ;if pxcor >= 8 and pxcor <= 130 and pycor = 107  [set pcolor red + 1]
    if pxcor >= 8 and pxcor <= 144 and pycor = 71  [set pcolor red + 1]
    if pxcor = 8 and pycor >= 60 and pycor <= 75   [set pcolor red + 1]
   ; if pxcor >= 8 and pxcor <= 130 and pycor = 64  [set pcolor red + 1]
    if pxcor >= 8 and pxcor <= 153 and pycor = 28  [set pcolor red + 1]
    if pxcor = 8 and pycor >= 17 and pycor <= 32   [set pcolor red + 1]
    ;if pxcor >= 8 and pxcor <= 130 and pycor = 21  [set pcolor red + 1]

    if pxcor = 18 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 28 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 42 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 52 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 62 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 76 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 86 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 96 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 110 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 120 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]
    if pxcor = 130 and pycor <= 118 and pycor >= 103 [set pcolor red + 1]

    if pxcor = 18 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 28 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 42 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 52 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 62 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 76 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 86 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 96 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 110 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 120 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]
    if pxcor = 130 and pycor <= 75 and pycor >= 60 [set pcolor red + 1]

    if pxcor = 18 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 28 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 42 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 52 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 62 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 76 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 86 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 96 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 110 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 120 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]
    if pxcor = 130 and pycor <= 32 and pycor >= 17 [set pcolor red + 1]

    if pxcor = 144 and pycor <= 27 and pycor >= 17 [set pcolor red + 1]
  ]
  set p-valids patches with [pcolor = red + 1]
end


to makemap
  ask patches [
    ; стены
    set pcolor white
    if pxcor >= 0 and pxcor <= 2 and pycor >= 0 and pycor <= 135 [set pcolor gray]
    if pxcor >= 160 and pxcor <= 162 and pycor >= 0 and pycor <= 138 [set pcolor gray]
    if pxcor >= 0 and pxcor <= 138 and pycor >= 133 and pycor <= 135 [set pcolor gray]
    if pxcor >= 0 and pxcor <= 162 and pycor >= 0 and pycor <= 2 [set pcolor gray]

    ; опоры
    if pxcor >= 34 and pxcor <= 36 and pycor >= 121 and pycor <= 132 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 121 and pycor <= 132 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 121 and pycor <= 132 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 121 and pycor <= 138 [set pcolor gray]
    if pxcor >= 34 and pxcor <= 36 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 34 and pxcor <= 36 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 34 and pxcor <= 36 and pycor >= 3 and pycor <= 14 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 3 and pycor <= 14 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 3 and pycor <= 14 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 3 and pycor <= 14 [set pcolor gray]
  ]
  ;ключевые координаты
  set positions
  [
    [126 119] [116 119] [106 119] [92 119] [82 119] [72 119] [58 119]
    [48 119] [38 119] [24 119]  [14 119] [4 119] ;[4 90] [14 90]
    [24 90] [38 90]
    [48 90] [58 90] [72 90] [82 90] [92 90] [106 90] [116 90] [126 90]      ;1 и 2 ряды

    [126 76] [116 76] [106 76] [92 76] [82 76] [72 76] [58 76]
    [48 76] [38 76] [24 76] ;[14 76] [4 76] [4 47] [14 47]
    [24 47] [38 47]   ;3 и 4 ряды
    [48 47] [58 47] [72 47] [82 47] [92 47] [106 47] [116 47] [126 47]

    [126 33] [116 33] [106 33] [92 33] [82 33] [72 33] [58 33]
    [48 33] [38 33] [24 33] ;[14 33] [4 33]
    [4 4] [14 4] [24 4] [38 4]    ;5 и 6 ряды
    [48 4] [58 4] [72 4] [82 4] [92 4] [106 4] [116 4] [126 4] [140 4] [150 4]
  ]
  let i 1
  foreach positions [
    pos ->
    let x item 0 pos
    let y item 1 pos

    ask patch x y
    [
      set chosen? false
      set ParkingNumber i   ; для номера позиции парковки
      set free? true

      ifelse i <= 9 [
        let px x + 5         ;корректировка подписи с номером места 1-9
        let py y + 6
        ask patch px py [

          if labelflag? = true [
            set plabel i
            set plabel-color black
          ]
        ]
      ]
      [
        let px x + 6         ;корректировка подписи с номером места 10-74
        let py y + 6
        ask patch px py [
          if labelflag? = true [
          set plabel i set plabel-color black]
        ]
      ]
      ifelse (x = 140 or x = 150) and (y = 4) [
        set VIPplace 1
      ]
      [
        set VIPplace 0
      ]
        coloring x y gray 3

    ]
    set i i + 1
  ]
end



to prepareAstar
  redd
  set p-valids patches with [pcolor = red + 1]
  ask patches with [pcolor = red + 1]
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]


  set Start patch 145 130
  ask Start [set pcolor white]
  ; Create a turtle to draw the path (when found)
  crt 1
  [
    ht
    set size 3
    set pen-size 2
    set shape "dot"
  ]
end


; Patch report to estimate the total expected cost of the path starting from
; in Start, passing through it, and reaching the #Goal
to-report Total-expected-cost [#Goal]
  report Cost-path + Heuristic #Goal
end

; Patch report to reurtn the heuristic (expected length) from the current patch
; to the #Goal
to-report Heuristic [#Goal]
  report distance #Goal
end

; A* algorithm. Inputs:
;   - #Start     : starting point of the search.
;   - #Goal      : the goal to reach.
;   - #valid-map : set of agents (patches) valid to visit.
; Returns:
;   - If there is a path : list of the agents of the path.
;   - Otherwise          : false

to-report A* [#Start #Goal #valid-map]
  ; clear all the information in the agents
  ask #valid-map with [visited?]
  [
    set father nobody
    set Cost-path 0
    set visited? false
    set active? false
  ]
  ; Active the staring point to begin the searching loop
  ask #Start
  [
    set father self
    set visited? true
    set active? true
  ]
  ; exists? indicates if in some instant of the search there are no options to
  ; continue. In this case, there is no path connecting #Start and #Goal
  let exists? true
  ; The searching loop is executed while we don't reach the #Goal and we think
  ; a path exists
  while [not [visited?] of #Goal and exists?]
  [
    ; We only work on the valid pacthes that are active
    let options #valid-map with [active?]
    ; If any
    ifelse any? options
    [
      ; Take one of the active patches with minimal expected cost
      ask min-one-of options [Total-expected-cost #Goal]
      [
        ; Store its real cost (to reach it) to compute the real cost
        ; of its children
        let Cost-path-father Cost-path
        ; and deactivate it, because its children will be computed right now
        set active? false
        ; Compute its valid neighbors
        let valid-neighbors neighbors with [member? self #valid-map]
        ask valid-neighbors
        [
          ; There are 2 types of valid neighbors:
          ;   - Those that have never been visited (therefore, the
          ;       path we are building is the best for them right now)
          ;   - Those that have been visited previously (therefore we
          ;       must check if the path we are building is better or not,
          ;       by comparing its expected length with the one stored in
          ;       the patch)
          ; One trick to work with both type uniformly is to give for the
          ; first case an upper bound big enough to be sure that the new path
          ; will always be smaller.
          let t ifelse-value visited? [ Total-expected-cost #Goal] [2 ^ 20]
          ; If this temporal cost is worse than the new one, we substitute the
          ; information in the patch to store the new one (with the neighbors
          ; of the first case, it will be always the case)
          if t > (Cost-path-father + distance myself + Heuristic #Goal)
          [
            ; The current patch becomes the father of its neighbor in the new path
            set father myself
            set visited? true
            set active? true
            ; and store the real cost in the neighbor from the real cost of its father
            set Cost-path Cost-path-father + distance father
            set Final-Cost precision Cost-path 3
          ]
        ]
      ]
    ]
    ; If there are no more options, there is no path between #Start and #Goal
    [
      set exists? false
    ]
  ]
  ; After the searching loop, if there exists a path
  ifelse exists?
  [
    ; We extract the list of patches in the path, form #Start to #Goal
    ; by jumping back from #Goal to #Start by using the fathers of every patch
    let current #Goal
    set Final-Cost (precision [Cost-path] of #Goal 3)
    let rep (list current)
    While [current != #Start]
    [
      set current [father] of current
      set rep fput current rep
    ]
    report rep
  ]
  [
    ; Otherwise, there is no path, and we return False
    report false
  ]
end

; Axiliary procedure to lunch the A* algorithm between random patches
to Look-for-Goal
  ; Take one random Goal
  let Goal one-of p-valids
  ; Compute the path between Start and Goal
  let path  A* Start Goal p-valids
  ; If any...
  ifelse path != false [
    ; Take a random color to the drawer turtle
    ask turtle 0 [set color (lput 150 (n-values 3 [100 + random 155]))]
    ; Move the turtle on the path stamping its shape in every patch
    foreach path [ ?1 ->
      ask turtle 0 [
        move-to ?1
        stamp] ]
    ; Set the Goal and the new Start point
    ;set Start Goal
  ]
  [Look-for-Goal]
end








; Auxiliary procedure to clear the paths in the world
to clean
  cd
end









;===============================================================================================================================================================
;===============================================================================================================================================================
;================================================================================================================================================================
;===============================================================================================================================================================
;=================================================================================================================================================================

to setupBooking
  clear-all
  prepareAstar
  set mouse-clicked? false
  makemappp
  set Purchasing_Cart []
  set TimerFlag false
  set TimeConstCounter 5 ; время, отведенное на оплату (секунды)
  set ReadyToPay? false
  reset-ticks
end

; Axiliary procedure to lunch the A* algorithm between random patches
to PathFinder

  ifelse (AstarY = 119) or (AstarY = 76) or (AstarY = 33) [
    set AstarY AstarY - 4
  ]
  [
    set AstarY AstarY + 16]

  set AstarX AstarX + 4





  ; Take one random Goal
  let Goal patch AstarX AstarY
  ; Compute the path between Start and Goal
  let path  A* Start Goal p-valids
  ; If any...
  ifelse path != false [
    ; Take a random color to the drawer turtle
    ask turtle 0 [set color (lput 150 (n-values 3 [100 + random 155]))]
    ; Move the turtle on the path stamping its shape in every patch
    foreach path [ ?1 ->
      ask turtle 0 [
        move-to ?1
        stamp] ]
    ; Set the Goal and the new Start point
    ;set Start Goal
  ]
  [Look-for-Goal]
end

to mouse-manager
  ifelse mouse-down?
  [
    if not mouse-clicked?
    [
      set mouse-clicked? true
      set xcord mouse-xcor
      set ycord mouse-ycor
      checking

    ]
  ]
  [
    set mouse-clicked? false
  ]
end


to go
  mouse-manager
  if TimerFlag = true [
    set TimeCounter TimeConstCounter - round (timer)
    if Payed? = true
    [
      paySuccess
    ]
    if TimeCounter = 0
    [
      output-print (word "Время оплаты вышло. Попробуйте снова ")
      set TimerFlag false
    ]
  ]
  set Payed? false
  tick
end

to checking



  foreach positions [
    pos ->
    let x item 0 pos
    let y item 1 pos


    if xcord >= x and xcord <= x + 8            ; проверка, нажата ли
    [                                           ; мышь в области места
      if ycord >= y and ycord <= y + 12         ; для парковки
      [
        ask patch x y
        [

          if statusBefore = "свободно" and chosen? = true  ; проверяем, выбрано ли место (нажали на голубой)
          [
            coloring x y lime 1.2
            output-print (word "Место " [ParkingNumber] of patch x y ". отказ от резерва")
            set Purchasing_Cart remove ParkingNumber Purchasing_Cart
            set booking_status? false
          ]

          if statusBefore = "свободно" and chosen? = false ; проверяем, свободно ли место (нажали на зеленый)
          [
            ;coloring x y sky 1.2
            coloring x y cyan 0
            output-print (word "Место " [ParkingNumber] of patch x y " выбрано для резерва")
            set Purchasing_Cart lput ParkingNumber Purchasing_Cart
            set AstarX x
            set AstarY y
            set booking_status? true
          ]
          ;show Purchasing_Cart
          if booking_status? = false [set chosen? false]   ; изменение статуса брони на отказ
          if booking_status? = true [set chosen? true]   ; изменение статуса брони на согласие
        ]
      ]

    ]
  ]
end



to makemappp
  ask patches [
    ; стены
    set pcolor white
    if pxcor >= 0 and pxcor <= 2 and pycor >= 0 and pycor <= 135 [set pcolor gray]
    if pxcor >= 160 and pxcor <= 162 and pycor >= 0 and pycor <= 138 [set pcolor gray]
    if pxcor >= 0 and pxcor <= 138 and pycor >= 133 and pycor <= 135 [set pcolor gray]
    if pxcor >= 0 and pxcor <= 162 and pycor >= 0 and pycor <= 2 [set pcolor gray]
    ; опоры
    if pxcor >= 34 and pxcor <= 36 and pycor >= 121 and pycor <= 132 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 121 and pycor <= 132 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 121 and pycor <= 132 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 121 and pycor <= 138 [set pcolor gray]
    if pxcor >= 34 and pxcor <= 36 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 78 and pycor <= 100 [set pcolor gray]
    if pxcor >= 34 and pxcor <= 36 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 35 and pycor <= 57 [set pcolor gray]
    if pxcor >= 34 and pxcor <= 36 and pycor >= 3 and pycor <= 14 [set pcolor gray]
    if pxcor >= 68 and pxcor <= 70 and pycor >= 3 and pycor <= 14 [set pcolor gray]
    if pxcor >= 102 and pxcor <= 104 and pycor >= 3 and pycor <= 14 [set pcolor gray]
    if pxcor >= 136 and pxcor <= 138 and pycor >= 3 and pycor <= 14 [set pcolor gray]
  ]

  set positions
  [ [126 119] [116 119] [106 119] [92 119] [82 119] [72 119] [58 119]
    [48 119] [38 119] [24 119] [14 119] [4 119] ;[4 90] [14 90]
    [24 90] [38 90]
    [48 90] [58 90] [72 90] [82 90] [92 90] [106 90] [116 90] [126 90]      ;1 и 2 ряды

    [126 76] [116 76] [106 76] [92 76] [82 76] [72 76] [58 76]
    [48 76] [38 76] [24 76] ; [14 76] [4 76] [4 47] [14 47]
    [24 47] [38 47]   ;3 и 4 ряды
    [48 47] [58 47] [72 47] [82 47] [92 47] [106 47] [116 47] [126 47]

    ;надо тестить:начало
    [126 33] [116 33] [106 33] [92 33] [82 33] [72 33] [58 33]
    [48 33] [38 33] [24 33] ;[14 33] [4 33]
    [4 4] [14 4] [24 4] [38 4]    ;5 и 6 ряды
    [48 4] [58 4] [72 4] [82 4] [92 4] [106 4] [116 4] [126 4] [140 4] [150 4]
    ;надо тестить:конец

  ]
  let i 1
  foreach positions [
    pos ->
    let x item 0 pos
    let y item 1 pos

    ask patch x y
    [
      set chosen? false
      set ParkingNumber i   ; для номера позиции парковки


      ifelse i <= 9 [
        let px x + 5
        let py y + 6
        ask patch px py [set plabel i set plabel-color black]
      ]
      [
        let px x + 6
        let py y + 6
        ask patch px py [set plabel i set plabel-color black]
      ]


      ifelse (x = 140 or x = 150) and (y = 4) and (hours >= 7 and hours <= 20)
      [
        set VIPplace "YES"
        set statusbefore "свободно"
        coloring x y lime 1.2
      ]
      [
        set VIPplace "NO"
        let r random 3
        ifelse r = 2
        [
          set statusBefore "свободно" ; отмечаем место как "свободное"
          coloring x y lime 1.2
        ]
        [
          set statusBefore "занято"; отмечаем место как "занятое"
          coloring x y gray 3
        ]

    ]
    ]
    set i i + 1
  ]
end

to amam
  foreach positions [
    pos ->
    let x item 0 pos
    let y item 1 pos
    coloring x y lime 1.2

    ask patch x y [
      set statusBefore "свободно" ; отмечаем место как "свободное"
    ]
  ]

  let prepa [2 5 6 7 8 9 11 12 14 18 20 21 26 28 30 33 35 45 47 49 55 59 62 65]
  foreach prepa [
  PN ->
    ask patches with [ParkingNumber = PN]
    [
      let temx pxcor
      let temy pycor
      set statusBefore "занято"; отмечаем место как "занятое"
       coloring temx temy gray 3
    ]
  ]
end


to restore
  clear-output
  foreach positions
  [
    pos ->
    let x item 0 pos
    let y item 1 pos

    ask patch x y
    [
      set chosen? false
      set Purchasing_Cart []
      ifelse statusBefore = "свободно"
      [
        coloring x y lime 1.2
      ]
      [
        coloring x y gray 3
      ]
    ]
  ]
end

to coloring [px py namecolor z]
  ask patches with
  [
    pxcor >= px and pxcor <= px + 8 and pycor >= py and pycor <= py + 12  ; обращаемся к патчам выбранного места
  ]
  [
    set pcolor namecolor + z   ; отображаем место как желанное для резерва (красим в голубой)
  ]
end


to cost_update
  let cart_length length Purchasing_Cart
  let price 50
  if booking_time >= 8 [set price 30]
  ;show cart_length
  ;show (word "таймер:" booking_time)
  let cost cart_length * Price * booking_time

  if cart_length = 0 [
    output-print (word "____________________________________")
    output-print (word "Бронирование невозможно")
    output-print (word "Вы не выбрали место для бронирования")
    set ReadyToPay? false
    stop
  ]
  if booking_time = 0 [
    output-print (word "____________________________________")
    output-print (word "Бронирование невозможно")
    output-print (word "Вы не установили время бронирования")
    set ReadyToPay? false
    stop
  ]
  output-print (word "____________________________________")
  ifelse cart_length = 1
  [
    output-print (word "Выбранное место: " Purchasing_Cart ".")
    output-print (word "Стоимость брони: " cost " руб.")
    set ReadyToPay? true
  ]

  [
    output-print (word "Кол-во мест: " cart_length ".")
    output-print (word "Список мест: " Purchasing_Cart ".")
    output-print (word "Стоимость брони: " cost " руб.")
    set ReadyToPay? true
  ]
end

to buy
  ifelse ReadyToPay? = true [
  reset-timer
  set TimerFlag true
  output-print (word "У вас есть 5 минут для оплаты (5 секунд)")
;if TimerFlag = true [ output-print (word "Секунды: " round (timer)) ]
  set TimeCounter 5
  ]
  [
    output-print (word "Оплата невозможна. Для начала узнайте стоимость")
  ]

  ;output-print (word "Секунды: " timer)
end

to paySuccess
  output-print (word "Оплата проведена успешно")
  foreach purchasing_cart
  [
   PN ->
    ask patches with [ParkingNumber = PN]
    [
      let temx pxcor
      let temy pycor
      set statusBefore "занято"; отмечаем место как "занятое"
      coloring temx temy gray 3
    ]
  ]
  set TimerFlag false
end
@#$#@#$#@
GRAPHICS-WINDOW
428
12
1272
719
-1
-1
5.1324
1
18
1
1
1
0
0
0
1
0
162
0
135
1
1
1
ticks
30.0

BUTTON
20
40
87
73
setup
setupStandart
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
91
40
154
73
go
goStandart
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
372
119
406
Убрать путь
clean
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
78
117
111
NIL
spawn_cars
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
21
498
405
692
11

SWITCH
147
453
241
486
Payed?
Payed?
1
1
-1000

INPUTBOX
20
264
116
324
booking_time
6.0
1
0
Number

BUTTON
20
413
144
446
Вывести стоимость
cost_update
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
19
451
133
484
Перейти к оплате
buy
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
20
221
84
254
сброс
restore
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
19
183
86
216
setup
setupBooking\n  changetime
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
93
182
156
215
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
25
10
105
32
Режим 1
18
0.0
1

TEXTBOX
21
154
94
176
Режим 2
18
0.0
1

TEXTBOX
172
181
322
199
Создание и запуск мира\n
11
0.0
1

TEXTBOX
92
225
242
253
Сброс выбранных позиций для бронирования
11
0.0
1

TEXTBOX
121
267
270
325
Количество часов, на которое хотите зарезервировать место
11
0.0
1

TEXTBOX
262
441
412
483
Нажмите на флаг, чтобы симулировать успешное проведение оплаты
11
0.0
1

SWITCH
20
115
138
148
labelFlag?
labelFlag?
0
1
-1000

BUTTON
20
333
118
366
Найти путь
PathFinder
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1292
12
1359
85
ЧЧ
hours
17
1
18

MONITOR
1363
13
1425
86
ММ
minutes
17
1
18

PLOT
1298
477
1867
684
Скорость машин
NIL
NIL
0.0
10.0
-0.1
0.6
true
false
"" ""
PENS
"pen-0" 1.0 0 -7500403 true "" ""

TEXTBOX
184
51
334
69
Создание и запуск мира\n
11
0.0
1

TEXTBOX
129
86
279
104
Создание агента (машины)
11
0.0
1

TEXTBOX
150
119
300
147
Отображение номера парковочных мест
11
0.0
1

TEXTBOX
139
346
289
388
Отображает путь от входа в парковку до выбранного места парковки
11
0.0
1

PLOT
1575
211
1870
463
Типы машин
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Обычный" 1.0 0 -16777216 true "" "plot cDefault"
"Бизнес" 1.0 0 -13840069 true "" "plot cBusiness"
"Скорая помощь" 1.0 0 -2674135 true "" "plot cAmbulance"

PLOT
1297
212
1569
462
Сейчас на парковке
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Обычные" 1.0 0 -16777216 true "" "plot count turtles with [typeofcompany = \"Default\"]"
"Бизнес" 1.0 0 -11085214 true "" "plot count turtles with [typeofcompany = \"Business\"]"
"Скорая помощь" 1.0 0 -2674135 true "" "plot count turtles with [typeofcompany = \"Ambulance\"]"

MONITOR
1296
91
1408
148
Мест свободно
count patches with [statusBefore = \"свободно\"]
17
1
14

MONITOR
1411
90
1506
147
Всего мест
length positions
17
1
14

MONITOR
1296
151
1507
208
Кол-во машин на парковке
count turtles with [shape = \"cartop\"]
17
1
14

SWITCH
280
226
388
259
labelflag?
labelflag?
0
1
-1000

BUTTON
1702
74
1766
107
NIL
amam
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
true
0
Polygon -1 true false 90 255 210 255 210 30 90 30 90 255
Polygon -1 true false 150 15 120 15 90 30 90 75 90 255 90 255 105 255 150 255 195 255 210 255 210 255 210 75 210 30 180 15
Polygon -16777216 true false 205 74 135 75 210 60
Polygon -16777216 true false 95 74 165 75 90 60
Rectangle -13345367 true false 105 90 135 105
Rectangle -13345367 true false 165 90 195 105
Rectangle -16777216 true false 135 90 165 105
Rectangle -2674135 true false 135 150 165 240
Rectangle -2674135 true false 105 180 195 210
Polygon -16777216 true false 90 60 105 45 195 45 210 60
Polygon -16777216 true false 90 60 150 75 210 60

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

cartop
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 true 210 165 195 165
Line -7500403 true 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
