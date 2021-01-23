;;author: Gildas Assogba
__includes ["biomtransfer.nls" "market.nls" "message.nls" "exportresults.nls"]

extensions [csv]
globals [
  season;;type of season: 0=bad, 1=good, 2=very good
  saison;; explanation of season, see set up
  month
  mois
  ngseason;;ngseason: grain units per season
  nrseason;; nrseason: residue units
  cultivplot;; cultivated plots
  bushplot;;bush
  farmers;;farms
  farmi;;list of farms
  graine
  resid
  accessresid;;access to residue y/n
  mn;;event: manure creation on bushplot, happen once
  cc;;animal creation for farm, happen once
  maxc maxr maxd maxp maxrc;;number of farm owing a certain type of animal
  canharvest;
  exchg;if one biomass exchange already occured, used in biomexchange
  warn;display warnings related to livestock
  ;feedfam;; control family feeding (grain)
  year
  forage;livestock feeding by farmer
  day;used in reproduce and nextmonth
  idplayer; list of players
  nj; index for players list
  headoutput;;head of data to be exported in separated file
  output;;data to be exported in separated file
  flux;;fluxes between players
  messages;;list of messages
  buysell;;list of selling and buying
]

breed [joueurs joueur]
directed-link-breed [biom_owner a-biom_owner]
directed-link-breed [biom_transfer a-biom_transfer]

patches-own [
  residue;;crop residue
  grain;;grain produced on agricultural plots
  grass;; grass on bush plots only
  cultiv;; is the patch cultivated or not?y/n
  ferti;;fertilized plot?y/n
  manu;;manure applied to plot?y/n
  harvested;;is plot harvested? y/n
  mulch;;amount of residue on field when starting a new year
  animhere;;total of animal on a cultivated patch, used in getmanure and livsim
]

joueurs-own [
  pseudo; name the player use entering the game
  idplay;
  residue_on_field
  send_biomass
  send_to
  send_how_much
  buy_what
  who_buy
  amount_buy
  sell_what
  who_sell
  amount_sell
  biom_weight
  message_text
  message_who
  open_field?
]

turtles-own [
  pos
  nature
  typo
  nplot
  playerpos
  player
  farm
  family_size
  ncow
  ndonkey
  nsrum
  npoultry
  nfertilizer
  ncart
  ntricycle
  ngrain
  nresidue;residue harvested
  nresiduep;residue on plots
  nconc
  nmanure
  onfarm_inc
  offfarm_inc
  fertilized
  canmove; distinguish moving agent from fictive ones
  energy;;of livestock
  neat;;number of times a residue agent is grazed
  open;;residue available for grazing
  foreignaccess;; other farm can access residue?
  grazed;;animal already ate?
  state;of livestock skinny medium fat
  repro;if an animal already reproduce during one year, y/n
  food_unsecure;; number of person food unsecure in the HH
  feedfam
  hunger;increase if an animal did not eat in a step, see reproduce
  nf;see livupdate, for fertilizer
  mulch?;;used to determined if a residue can be turned into mulch
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;HUBNET;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to startup
  hubnet-reset
  set-up
  listen-clients
end

to listen-clients
  while [ hubnet-message-waiting? ] [
    hubnet-fetch-message
    ifelse hubnet-enter-message? [
      create-new-player
      ask joueurs [update]
    ] [
      ifelse hubnet-exit-message? [
        remove-player
      ] [
        ask joueurs with [ pseudo = hubnet-message-source ] [
          execute-command hubnet-message-tag
        ]
      ]
    ]
  ]
end

to create-new-player
  set idplayer (list "player 1" "player 2" "player 3" "player 4")
  ifelse nj < 4 [
    create-joueurs 1 [
      set pseudo hubnet-message-source
      set idplay item nj idplayer
      set hidden? true
      set residue_on_field 0
      set send_biomass "residue"
      set send_to "player 1"
      set send_how_much 0
      set buy_what "residue" set who_buy "player 1" set amount_buy 0
      set sell_what "residue" set who_sell "player 1" set amount_sell 0
      set biom_weight "skinny"
      set open_field? true
      set message_who "player 1"
      move-to patch-at 0 0
    ]
    set nj nj + 1]
  [user-message "Maximum number of player reached"]
end

to remove-player
  ask joueurs with [pseudo = hubnet-message-source][die]
end

to go
  listen-clients
  ask joueurs [update]
end

to update
  let stck 0 let stck2 0 let rskc 0 let rsks 0 let rskd 0
  let idplays idplay
  hubnet-send pseudo "nplot" item 0[nplot] of farmers with [player = idplays]
  hubnet-send pseudo "cattle" item 0[ncow] of farmers with [player = idplays]
  hubnet-send pseudo "srum" item 0[nsrum] of farmers with [player = idplays]
  hubnet-send pseudo "donkey" item 0[ndonkey] of farmers with [player = idplays]
  hubnet-send pseudo "poultry" item 0[npoultry] of farmers with [player = idplays]
  hubnet-send pseudo "nplot" item 0[nplot] of farmers with [player = idplays]
  hubnet-send pseudo "fertilizer" item 0[nfertilizer] of farmers with [player = idplays]
  hubnet-send pseudo "tricycle" item 0[ntricycle] of farmers with [player = idplays]
  hubnet-send pseudo "cart" item 0[ncart] of farmers with [player = idplays]
  hubnet-send pseudo "grain" item 0[ngrain] of farmers with [player = idplays]
  hubnet-send pseudo "residue harv" item 0[nresidue] of farmers with [player = idplays]
  ask farmers with [player = idplays][
    set stck count out-link-neighbors with [typo = "residue" and hidden? = true and shape = "star"]
    set stck2 count out-link-neighbors with [typo = "residue" and hidden? = false and shape = "star"]
    set rskc count out-link-neighbors with [shape = "cow" and canmove = "yes" and hunger > 0]
    set rsks count out-link-neighbors with [shape = "sheep" and canmove = "yes" and hunger > 0]
    set rskd count out-link-neighbors with [shape = "wolf" and canmove = "yes" and hunger > 0]
  ]
  hubnet-send pseudo "stock residue" stck
  hubnet-send pseudo "residue on field" stck2
  hubnet-send pseudo "manure" item 0[nmanure] of farmers with [player = idplays]
  hubnet-send pseudo "conc" item 0[nconc] of farmers with [player = idplays]
  hubnet-send pseudo "manure" item 0[nmanure] of farmers with [player = idplays]
  hubnet-send pseudo "off farm" item 0[offfarm_inc] of farmers with [player = idplays]
  hubnet-send pseudo "on farm" item 0[onfarm_inc] of farmers with [player = idplays]
  hubnet-send pseudo "risky cow" rskc hubnet-send pseudo "risky srum" rsks hubnet-send pseudo "risky donkey" rskd
  hubnet-send pseudo "food unsecure" item 0[food_unsecure] of farmers with [player = idplays]
  hubnet-send pseudo "pseudo_" pseudo
  hubnet-send pseudo "name" idplay
  hubnet-send pseudo "month" month
  hubnet-send pseudo "year" year
  hubnet-send pseudo "season" season
end

to execute-command [command ]
  if command = "transfer_biomass" [biomtransfer]
  if command = "Market" [market]
  if command = "feed family" [feedfamily idplay livupdate idplay]
  if command = "send message" [message]
  if command != "transfer_biomass" and command != "Market"
  and command != "feed family" and command != "message"[
   receive-message
  ]
end


to set-up
  ;clear-drawing clear-patches
  clear-all-plots clear-patches
  ask turtles with [breed != joueurs][die]
  set nj 0
  set cc 0
  set idplayer (list "player 1" "player 2" "player 3" "player 4")
  set season one-of (range 0 3 1)
  if season = 0 [set saison "Bad :("]
  if season = 1 [set saison "Good :)"]
  if season = 2 [set saison "Very good :)"]
  set mois (list "July" "November" "December"
    "February" "April" "June")
  set farmers turtles with [shape = "person farmer"]
  set month item 0 mois
  set canharvest 0
  set year 1 set day 0
  reset-ticks
  set headoutput (word
    (list "year" "month" "p1type" "p2type" "p3type" "p4type" "p1cattle" "p2cattle" "p3cattle" "p4cattle"
      "p1srum" "p2srum" "p3srum" "p4srum" "p1donkey" "p2donkey" "p3donkey" "p4donkey" "p1famsize" "p2famsize"
      "p3famsize" "p4famsize" "p1cart" "p2cart" "p3cart" "p4cart" "p1trcycl" "p2trcycl" "p3trcycl" "p4trcycl"
      "p1fert" "p2fert" "p3fert" "p4fert" "p1man" "p2man" "p3man" "p4man" "p1residstck" "p2residstck" "p3residstck" "p4residstck"
      "p1residsoil" "p2residsoil" "p3residsoil" "p4residsoil" "p1residsoilp" "p2residsoilp" "p3residsoilp" "p4residsoilp"
      "p1conc" "p2conc" "p3conc" "p4conc" "p1fdunsec" "p2fdunsec" "p3fdunsec" "p4fdunsec" "p1onfinc" "p2onfinc" "p3onfinc" "p4onfinc"
      "p1offinc" "p2offinc" "p3offinc" "p4offinc")
  )
  set flux []
  set messages []
  set buysell []
  ask patches [set animhere []]
end

to nextmonth
  set warn 0
  export
  set flux []
  set messages []
  set buysell []
  tick
  set month item ticks mois
  let players1 (list "player 1" "player 2" "player 3" "player 4")
  let animals (list "cow" "sheep" "wolf")
  let gle (list "1" "2" "3" "4")
  let kk 0
  foreach players1 [
    let jj 0
   foreach animals[
     livsim item kk players1 item jj animals
      set jj jj + 1
    ]
    liens item kk gle
    livupdate item kk players1
    set kk kk + 1
  ]
  set kk 0
  set players1 (list feedconc_p1 feedconc_p2 feedconc_p3 feedconc_p4)
  foreach players1 [concfeed item kk players1 set kk kk + 1]
  ;if month = "November" [user-message "You can now harvest :)"]

  if ticks = 5 [set year year + 1 set month item 0 mois reset-ticks
  user-message "New season! Time to sow"
    ask farmers with [nplot = 7][set offfarm_inc offfarm_inc + 50]
    ask farmers with [nplot != 7][set offfarm_inc offfarm_inc + 10]
    ask farmers [
      set nmanure count out-link-neighbors with [shape = "cow" and canmove = "yes"];1cow=1manure/year
    ]
    ask turtles with [shape = "box"][die]
    ask turtles with [canmove = "yes"][move-to one-of patches with [pcolor = (rgb 0 100 0)]]
    ;ask turtles with [shape = "cow" or shape = "sheep" or shape = "wolf" and canmove = "yes"][set energy 4]
    initbush
    set canharvest 0 ask farmers [set feedfam 0]
    set season one-of (range 0 3 1)
    if season = 0 [set saison "Bad :("]
    if season = 1 [set saison "Good :)"]
    if season = 2 [set saison "Very good :)"]
  ]
  set day day + 1
end
to environment
  ;;ressources
  ask patches with [pxcor = min-pxcor and (pycor != 0 and pycor > min-pycor)][
   set pcolor white
  ]
  ask patches with [pycor = 0 and (pxcor != 0 and pxcor < max-pxcor)][
   set pcolor white
  ]

  ask patches with [pycor = min-pycor and (pxcor != 0 and pxcor < max-pxcor)][
   set pcolor white
  ]

  ask patches with [pxcor = max-pxcor and (pycor != 0 and pycor > min-pycor)][
    set pcolor white
  ]

  ask patches with [pcolor = white] [
    ask neighbors4[
      if pxcor != 0 and pycor > min-pycor and pxcor < max-pxcor [set pcolor white]
    ]
  ]

  ;;bordure
  ask patch 1 0 [set pcolor gray]
  ask patch 0 -1 [set pcolor gray]
  ask patch 1 -1 [set pcolor gray]
  ask patch 0 -11 [set pcolor gray]
  ask patch 1 -12 [set pcolor gray]
  ask patch 11 -12 [set pcolor gray]
  ask patch 12 -11 [set pcolor gray]
  ask patch 11 -11 [set pcolor gray]
  ask patch 12 -1 [set pcolor gray]
  ask patch 11 0 [set pcolor gray]
  ask patch 11 -1 [set pcolor gray]
  ask patch 1 -11 [set pcolor gray]
  ask patch 0 -12 [set pcolor gray]
  ask patch 0 0 [set pcolor gray]
  ask patch 12 -12 [set pcolor gray]
  ask patch 12 0 [set pcolor gray]

  ;;landscape
  ask  patch 2 -6
  [set pcolor rgb 0 255 0
   set plabel "1"
   ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "1"
    ]
  ]
  ask patch 2 -4 [
    set pcolor rgb 0 255 0
    set plabel "1"
  ]

  ask patch 6 -10
  [set pcolor rgb 0 255 0
    set plabel "2"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "2"
    ]
  ]
  ask patch 4 -10 [
    set pcolor rgb 0 255 0
    set plabel "2"
  ]

  ask patch 10 -6
  [set pcolor rgb 0 255 0
    set plabel "3"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "3"
    ]
  ]
  ask patch 8 -6 [
    set pcolor rgb 0 255 0
    set plabel "3"
  ]


  ask patch 6 -2
  [set pcolor rgb 0 255 0
    set plabel "4"
    ask neighbors with [pcolor = black][
      set pcolor rgb 0 255 0
      set plabel "4"
    ]
  ]
  ask patch 4 -2 [
    set pcolor rgb 0 255 0
    set plabel "4"
  ]
  ask patches with [pcolor = rgb 0 255 0][set plabel-color black]

  ;;market
  ask patch 5 -6 [set pcolor rgb 200 200 0]

  ;;bush
  ask patches with [pxcor <= 7 and pycor = -4 and pcolor = black][
    set pcolor rgb 0 100 0
  ]
  ask patch 8 -5 [
    set pcolor rgb 0 100 0
  ]
  ask patch 7 -5 [
    set pcolor rgb 0 100 0
  ]
  ask patches with [pxcor = 7 and pycor > -9 and pycor <= -5] [
    set pcolor rgb 0 100 0
  ]
  ask patches with [pxcor >= 2 and pxcor <= 6 and pycor = -8] [
    set pcolor rgb 0 100 0
  ]
  ask patches with [pxcor >= 2 and pxcor <= 3 and pycor = -9] [
    set pcolor blue
  ]
  ask patches with [pxcor = 3 and pycor <= -2 and pycor >= -3] [
    set pcolor blue
  ]

  ;;position 1
  farmres1 1 (range -2 -11 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 1

  farmres1 0 (range -3 -10 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 1

  ;;position 2
  farmres2 -11 (range 2 11 1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44)(list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 2

  farmres2 -12 (range 3 10 1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 2

  ;;position 3
  farmres1 11 (range -2 -11 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 3

  farmres1 12 (range -3 -10 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 3

  ;;position 4
  farmres2 -1 (range 10 1 -1) (list "person farmer" "tile stones" "cow" "wolf" "sheep" "bird" "drop" "car" "truck")
  (list 15 37 85 5 135 116 95 85 44) (list "famer" "land" "cattle" "donkey" "srum" "poultry" "fertilizer" "cart" "tricycle") 4

  farmres2 0 (range 9 2 -1) (list "checker piece 2" "tile water" "lightning" "triangle" "coin tails" "coin tails" "dot")
  (list 25 45 75 35 55 95 125) (list "grain" "residue" "conc" "manure" "onfarm inc" "off-farm inc" "seed") 4

  playerplace

  set farmi (list "1" "2" "3" "4")
  let playi (list player1type player2type player3type player4type)
  let ii 0
  foreach farmi [
    resdistrib item ii playi item ii farmi
    liens item ii farmi
    set ii ii + 1
  ]

  initbush;;create bush biomass
  ;fix heading of resources on white patches
  ask turtles with [typo = "manure" or typo = "fertilizer"
    or typo = "cattle" or typo = "srum"][
    set heading 0
  ]

  let players (list "player 1" "player 2" "player 3" "player 4")
  let animals (list "cow" "sheep" "wolf" "bird")
  let gle (list "1" "2" "3" "4")
  let kk 0
  foreach players [
    let jj 0
   foreach animals[
     livsim item kk players item jj animals
      set jj jj + 1
    ]
    ;liens item kk gle
    ask farmers with [player = item kk players][
      ask patches with [plabel = ""][set plabel "99"]
      let poss pos
      let nb nconc
      let nfert nfertilizer
      let nman nmanure
      ask out-link-neighbors with [shape = "lightning"] [
       hatch nb
      ]

      ask out-link-neighbors with [shape = "drop"][
        hatch nfert [
          set typo "fertilizer"
          set shape "drop"
          set color 96
          set size .75
          set heading one-of (range 0 360 90)
          move-to one-of patches with [(read-from-string plabel) = poss ]
          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here < 2]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here < 2]]

          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here = 0]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here = 0]]
        ]
      ]
      ask out-link-neighbors with [shape = "triangle"][
        hatch nman [
          set typo "manure"
          set shape "triangle"
          set color 36
          set size .75
          set heading one-of (range 0 360 90)
          move-to one-of patches with [(read-from-string plabel) = poss ]
          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here < 2]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here < 2]]

          if any? patches with [(read-from-string plabel) = poss and
            count turtles-here = 0]
          [move-to one-of patches with [(read-from-string plabel) = poss and
            count turtles-here = 0]]
        ]
      ]
      ask patches with [plabel = "99"][set plabel ""]
    ]

    liens item kk gle
    livupdate item kk players
    set kk kk + 1
  ]

  ;set kk 0

  ;foreach players [
  ;ask farmers with [player = item kk players][
  ;  ask out-link-neighbors with [shape = "drop" and color = 97][
  ;   die
  ;  ]
  ;]

   ; set kk kk + 1]

end

to farmres1 [p i j col typ ps]
  ;;function to dispose resources
  ;; vertical disposition
  let n 0
  foreach i [
    create-turtles 1 [
      let l item n i
      move-to patch p l
      set shape item n j
      set color item n col
      set pos ps
      set typo item n typ
    ]
    set n n + 1
  ]
end
to farmres2 [p i j col typ ps]
  ;;function to dispose resources
  ;; horizontal disposition
  let n 0
  foreach i [
    create-turtles 1 [
      let l item n i
      move-to patch l p
      set shape item n j
      set color item n col
      set pos ps
      set typo item n typ
    ]
    set n n + 1
  ]

end

to playerplace
  set farmers turtles with [shape = "person farmer"]
  ask farmers with [pos = player1pos] [set player "player 1"]
  ask turtles with [pos = player1pos] [set farm "1"]

  ask farmers with [pos = player2pos] [set player "player 2"]
  ask turtles with [pos = player2pos] [set farm "2"]

  ask farmers with [pos = player3pos] [set player "player 3"]
  ask turtles with [pos = player3pos] [set farm "3"]

  ask farmers with [pos = player4pos] [set player "player 4"]
  ask turtles with [pos = player4pos] [set farm "4"]

  ask turtles [set label farm set label-color red]
  ;;avoid more than one player per position
  let playpos (list player1pos player2pos player3pos player4pos)
  if sum playpos != 10 [
    user-message "More than one player in a position. Please check players position, reset and start again"
    stop
  ]
end

to resdistrib [typology ferme]
  ;; Subsistence-oriented crop farm
  if typology = "SOC" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 8
      set nplot 5
      set ncow one-of (range 0 4 1)
      set nsrum one-of (range 0 11 1)
      set npoultry one-of (range 3 11 1)
      set nfertilizer one-of (range 0 4 1)
      set ncart one-of (range 0 2 1)
      ifelse ncart > 0 [set ndonkey one-of (range 1 3 1)][set ndonkey one-of (range 0 3 1)]
      set ntricycle 0
      set ngrain 2
      set nresidue 0
      set nconc one-of (range 0 4 1)
      set nmanure ncow
      set onfarm_inc 20
      set offfarm_inc 10
    ]

  ]

  ;; Subsistence-oriented livestock farm
  if typology = "SOL" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 7
      set nplot 4
      set ncow one-of (range 0 3 1)
      set nsrum one-of (range 4 13 1)
      set npoultry one-of (range 2 16 1)
      set nfertilizer one-of (range 0 3 1)
      set ncart one-of (range 0 2 1)
      ifelse ncart > 0 [set ndonkey one-of (range 1 2 1)][set ndonkey one-of (range 0 2 1)]
      set ntricycle 0
      set ngrain 2
      set nresidue 0
      set nconc one-of (range 0 4 1)
      set nmanure ncow
      set onfarm_inc 25
      set offfarm_inc 10
    ]

  ]

  ;; Market-oriented diversified farm
  if typology = "MOD" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 12
      set nplot 7
      set ncow one-of (range 0 4 1)
      set ndonkey one-of (range 1 3 1)
      set nsrum one-of (range 5 18 1)
      set npoultry one-of (range 8 23 1)
      set nfertilizer one-of (range 0 4 1)
      set ncart 1
      set ntricycle one-of (range 0 2 1)
      set ngrain 2
      set nresidue 0
      set nconc one-of (range 0 6 1)
      set nmanure ncow
      set onfarm_inc 100
      set offfarm_inc 50
    ]

  ]

  ;; Land-constrained livestock farm
  if typology = "LCL" [

    ask turtles with [shape = "person farmer" and farm = ferme][
      set family_size 15
      set nplot 3
      set ncow one-of (range 2 7 1)
      set ndonkey one-of (range 0 3 1)
      set nsrum one-of (range 9 52 1)
      set npoultry one-of (range 0 28  1)
      set nfertilizer one-of (range 0 2 1)
      set ncart one-of (range 0 2 1)
      ifelse ncart > 0 [set ndonkey one-of (range 1 3 1)][set ndonkey one-of (range 0 3 1)]
      set ntricycle 0
      set ngrain 3
      set nresidue 0
      set nconc one-of (range 7 21 1)
      set nmanure ncow
      set onfarm_inc 100
      set offfarm_inc 10
    ]

  ]

end

to sow
  let fin ""
  ifelse month = "July" [
    ;set farmers turtles with [shape = "person farmer"]
    ask patches with [pcolor = rgb 0 255 0 and cultiv = "yes"][
      set mulch count turtles-here with [shape = "star" and hidden? = false and mulch? = true]
    ]
    ask turtles with [mulch? = true][set open "no" set hidden? true];;residue become mulch if not eaten for an entire season
    ask turtles with [typo = "fertilizer" and color = 96][die]
    ask turtles with [typo = "fertilizer" and color = 97][die]
    ask turtles with [typo = "manure" and color = 36][die]

    ask turtles-on patches with [pcolor = rgb 0 255 0][
      if typo != "fertilizer" or typo !="manure" and hidden? = false [
        die]
    ]
    set farmi [farm] of farmers
    let n 0
    let m 0

    foreach farmi [
      ask turtles with [farm = item n farmi and shape = "person farmer"][
        ;show nplot
        let nseed nplot
        let nfert nfertilizer
        let nman nmanure
        let posi pos
        ask patches with [plabel = ""][set plabel "99"]
        ifelse year = 1 [
          set fin patches with [(read-from-string plabel) = posi and pcolor != white]]
        [set fin patches with [cultiv = "yes"]];;cultivate the same plot each year
        ask patch-here[
          ;;seed
          sprout nseed [
            set typo "seed2"
            set farm item n farmi
            set label farm
            set shape "dot"
            set color 125
            move-to one-of fin with [count turtles-here with [typo ="seed2"] = 0]
          ]
          ;;old fertilizer/manure
          ask turtles with [[pcolor] of patch-here = rgb 0 255 0 and
            typo = "fertilizer" or typo = "manure" and hidden? = true
            and farm = item n farmi][
            set hidden? false
            set farm item n farmi
            move-to one-of fin with [count turtles-here with [typo ="seed2"] > 0]
          ]


          sprout nman [
            set typo "manure"
            set shape "triangle"
            set farm item n farmi
            set color 35
            set size .5
            move-to one-of fin with [count turtles-here >= 1]
            if count turtles-here with [typo = "manure"] > 2 [
              if any? patches with [(read-from-string plabel) = posi and pcolor != white
                and count turtles-here with [typo = "manure"] < 2 and count turtles-here with [typo = "seed2"] > 0][
                let destination patches with [(read-from-string plabel) = posi and pcolor != white
                  and count turtles-here with [typo = "manure"] < 2 and count turtles-here with [typo = "seed2"] > 0]
                move-to one-of destination;; try to put max of 2 manure per plot as beyond yield do not increase
              ]
            ]
          ]

          sprout nfert [
            set typo "fertilizer"
            set shape "drop"
            set color 95
            set farm item n farmi
            set size .5
            move-to one-of fin with [count turtles-here >= 1]
            if count turtles-here with [typo = "fertilizer"] > 2 [
              if any? patches with [(read-from-string plabel) = posi and pcolor != white
              and count turtles-here with [typo = "fertilizer"] < 2 and count turtles-here with [typo = "seed2"] > 0][
                let destination patches with [(read-from-string plabel) = posi and pcolor != white
                and count turtles-here with [typo = "fertilizer"] < 2 and count turtles-here with [typo = "seed2"] > 0]
                move-to one-of destination;; try to put max of 2 fertilizer per plot as beyond yield do not increase
              ]
            ]
          ]

        ]

      ]
    ;show farmi
      ;show xseed
      ;ask turtles with [farm = item n farmi and shape = "person farmer"][
       ; set nfertilizer 0 set nmanure 0
      ;]
      set n n + 1
    ]

    ;;conserve unused manure and fertilizer
    ask turtles with [typo = "fertilizer" and [pcolor] of patch-here != white][
      if count turtles-here with [typo = "fertilizer" and hidden? = false] > 2 [
       let rfert count turtles-here with [typo = "fertilizer" and hidden? = false] - 2
        ask n-of rfert turtles-here with [typo = "fertilizer" and hidden? = false][
         set color 95 set hidden? true set size .5
        ]
      ]
    ]

    ask turtles with [typo = "manure" and [pcolor] of patch-here != white][
      if count turtles-here with [typo = "manure" and hidden? = false] > 2 [
       let rfert count turtles-here with [typo = "manure" and hidden? = false] - 2
        show rfert
        ask n-of rfert turtles-here with [typo = "manure" and hidden? = false][
         set color 35 set hidden? true set size .5
        ]
      ]
    ]

    ask turtles-on patches with [pcolor = rgb 0 255 0][set label ""]
    ask patches with [plabel = "99"][set plabel ""]
    let seeds turtles with [typo = "seed2"]
    ;ask farmers [set nmanure 0 set nfertilizer 0 set ngrain 0]
    liens "1" liens "2" liens "3" liens "4"
  ]
  [user-message "You cannot sow, wait for July"]

end

to grow [taille]
  let g ""; variable to check the period is suitable for growing crops
  if month = "July" [set g "ok"]
  if g = "ok" [
    ask turtles-on patches with [pcolor = rgb 0 255 0][
      ask turtles-here with [typo = "seed2" or typo = "fertilizer" or typo = "manure" and hidden? = false][
        ask patch-here [
          set ferti count turtles-here with [typo = "fertilizer" and hidden? = false]
          set manu count turtles-here with [typo = "manure" and hidden? = false]
          set cultiv "yes"
          ;show manu
        ]

        die
      ]
    ]
    produce;;calculate harvest and display it
  ]

  bush
end

to produce
  ;set farmers turtles with [shape = "person farmer"]
  set farmi [farm] of farmers
  let n 0

  ;;basic prod according ot season
  if season = 0 [set ngseason 1 set nrseason 10]
  if season = 1 [set ngseason 2 set nrseason 11]
  if season = 2 [set ngseason 3 set nrseason 12]
  if month = "July" [
    ask patches with [plabel = ""][set plabel "99"]
    foreach farmi [

      ask farmers with [farm = item n farmi] [
        let posi pos
        set cultivplot patches with [(read-from-string plabel) = posi and cultiv = "yes"]

        ;;gain of grain and residue due to fertilizer
        ask cultivplot with [ferti > 0][
          if ferti > 2 [set ferti 2]; even if there is more than 2 only 2 will contribute to production
          sprout ferti [
            set typo "grain"
            set shape "cylinder"
            set size .75
            set color red
            set farm item n farmi
          ]

          sprout ferti [
            set typo "residue"
            set shape "star"
            set size .5
            set color yellow
            set farm item n farmi
          ]
        ]
        ;;gain of residue due to manure
        ask cultivplot with [manu > 0][
          if manu > 2 [set manu 2]
          sprout manu [
            set typo "residue"
            set shape "star"
            set size .5
            set color yellow
            set farm item n farmi
          ]
        ]

        ;;gain of residue due to mulch
        ;;4units of mulch for one residue
        let paille sum [mulch] of cultivplot
        ask n-of (floor (paille / 4)) patches [
          sprout 1 [
            set typo "residue"
            set shape "star"
            set size .5
            set color yellow
            set farm item n farmi
            move-to one-of cultivplot
          ]
        ]

        ask n-of (4 * floor (paille / 4)) out-link-neighbors with [shape = "star" and mulch? = true][die]

        ask cultivplot [
          set mulch count turtles-here with [shape = "star" and open = "no" and mulch? = true]
        ]

        ;;normal production depending on season
      ask cultivplot [

          sprout ngseason [
            set typo "grain"
            set shape "cylinder"
            set size .75
            set color red
            set farm item n farmi
          ]
          sprout nrseason [
            set typo "residue"
            set shape "star"
            set size .5
            set color yellow
            set farm item n farmi
          ]
        ]

        ]

        set n n + 1
        ]


    ask patches with [plabel = "99"][set plabel ""]
    ;ask turtles with [shape = "flower"][die]
  ]


end

to harvest [presid gamer]
  ;;presid is the proportion of residue harvested, see interface
  let farmii item 0 [farm] of farmers with [player = gamer]
  if month = "November" [
    ifelse canharvest < 4 [
    ask turtles with [typo = "grain" and shape = "cylinder"][
        set hidden? true
        ask patch-here [set harvested "yes"]
    ]

      ask farmers with [player = gamer] [
        ;;check if farm have resource to harvest a certain prop of biom
        if (presid / 100) > 0.5 [if ncart = 0 [
          user-message (word "You do not own a donkey cart or tricycle, you can harvest a maximum of 50% of your crop residue."
            " Update the proportion of residue to be harvested and try to harvest again.")
          stop
        ]]

        if (presid / 100) > 0.8 [ifelse ntricycle >= 1 [set presid presid][
          user-message (word "You do not own a tricycle, you can harvest a maximum of 80% of your crop residue."
            " Update the proportion of residue to be harvested and try to harvest again.")
          stop
      ]]

      liens farmii
        ;;residue harvested and left on field
      let tresid count out-link-neighbors with [typo = "residue" and shape = "star"]
      set tresid ceiling (tresid * presid / 100)
        ask n-of tresid out-link-neighbors with [typo = "residue" and shape = "star"] [
          set hidden? true
        ]

        ask out-link-neighbors with [typo = "residue" and shape = "star" and hidden? = false] [
          set mulch? true;;these residue can be turned into mulch if not grazed before new season
        ]

        ;;update grain and residue info in farms
        set graine count out-link-neighbors with [typo = "grain" and shape = "cylinder"]
        set resid count out-link-neighbors with [typo = "residue" and hidden? = true]
        set ngrain graine ;- 1; remove the ficitve one white plot
        set nresidue resid ;- 1; remove the ficitve one white plot
        set nresiduep count out-link-neighbors with [typo = "residue" and hidden? = false and shape = "star"];;residue on field

        ;;other farms access residue left on field
        if player = "player 1" [set accessresid open_field1?]
        if player = "player 2" [set accessresid open_field2?]
        if player = "player 3" [set accessresid open_field3?]
        if player = "player 4" [set accessresid open_field4?]
        if any? joueurs with [idplay = gamer][
          set accessresid item 0 [open_field?] of joueurs with [idplay = gamer]];;player has priority on game master
        ask out-link-neighbors with [typo = "residue" and shape = "star"][
          if accessresid = true [set foreignaccess "yes"]
        ]
      ]

      ask turtles with [typo = "residue" and shape = "star"] [set open "yes"]
    ][user-message "You already harvested"]
    set canharvest canharvest + 1
  ]
  ;[user-message "You cannot harvest, it is only possible in November"]
  ;if month = "November" and canharvest <= 4 [user-message "Feed your family with the grain harvested before next step"]
end

to initbush
  set bushplot patches with [pcolor = rgb 0 100 0]
  let nbush count bushplot
  set nbush nbush * 9

  create-turtles nbush [
    set shape "box"
    set size .25
    set color 135
    move-to one-of bushplot; with [count turtles-here with [shape = "box"] < ]
  ]

end

to bush
  ifelse (month = "August" or month = "September" or month = "October")[
    ask bushplot [
      sprout 3 [
        set shape "box"
        set size .25
        set color 135
      ]
    ]
  ]
  [
    ask bushplot with [count turtles-here with[shape = "box"] > 0][
      if count turtles-here with[shape = "box"] = 1 [
        ask one-of turtles-here with[shape = "box"][die]]
      if count turtles-here with[shape = "box"] >= 2 [
        ask n-of 2 turtles-here with[shape = "box"][die]]
    ]


  ]

end

to livsim [gamer animal]
  let farmlab item 0 [label] of farmers with [player =  gamer]
  let coul 0
  let nanim 0
  let sz 0;size of animals
  set maxc count farmers with [ncow > 0]
  set maxr count farmers with [nsrum > 0]
  set maxd count farmers with [ndonkey > 0]
  set maxp count farmers with [npoultry > 0]
  set maxrc maxc + maxr + maxd + maxp
  ifelse animal = "cow" [
    set coul cyan
    set maxc count farmers with [ncow > 0]
  ] [
    set coul white
    set maxc count farmers with [nsrum > 0]
  ]
  if animal = "wolf" [set coul gray]
  if animal = "bird" [set coul 116]
  ;;create cows

  if cc <= maxrc [
    set cc cc + 1
    ask farmers with [player = gamer][
      if animal ="cow" [set nanim ncow set sz 1.25]
      if animal = "sheep"[set nanim nsrum set sz .75]
      if animal = "wolf"[set nanim ndonkey set sz 1]
      if animal = "bird"[set nanim npoultry set sz 1]
      ifelse animal != "bird" [
        ask out-link-neighbors with [shape = animal and canmove = 0][
          hatch nanim [
            set color coul
            set size sz
            set energy 4
            set state "skinny"
            set repro "no"
            set canmove "yes"
            if random 101 > 50 [lt 1]
            move-to one-of patches with [pcolor = (rgb 0 100 0)]
          ]
        ]
      ][
        ask out-link-neighbors with [shape = animal][
          hatch nanim [
            set color coul
            set size sz
            set energy 4
            set state "skinny"
            set repro "no"
          ]
        ]
      ]
  ]]

  liens farmlab

   ;;cows movements on bushplot
  let cow turtles with [shape = animal and canmove = "yes" and farm = farmlab]
  ask cow with [grazed != "yes"][
    if (count turtles-here with [shape = animal and canmove = "yes"]) >
    (count turtles-here  with[shape = "box"])[
      if any? bushplot with [count turtles-here with [shape = animal and canmove = "yes"] <
        count turtles-here with [shape = "box"]] [
        move-to patch-here
      ]
    ]
  ]
  ask cow with [grazed != "yes"] [
    ifelse any? turtles-here with[shape = "box"][][
      if any? turtles with[shape = "box"] [
        move-to one-of bushplot with [count turtles with [shape = "box"] > 0]
      ]
    ]

  ]
  ;;eating grass
  let kil 0
  let kild 0
  ask cow with [grazed != "yes"][
    if any? turtles-here with[shape = "box"] [
        ifelse (animal = "cow" or animal = "wolf") [
          ask one-of turtles-here with[shape = "box" ][die]
          set energy energy + 1 set grazed "yes"
        ]

        [
          ask one-of turtles-here with[shape = "box"][die]
          set energy energy + 1 set grazed "yes"
        ]
      ;set energy energy + 1
      ;set grazed "yes"
    ]
  ]

  foreignresidue gamer
  grazeresidue gamer animal
  directfeed gamer
  concfeed gamer

  ;;manure left on 30% of bushplot. only happens after January
  ;if (month != "July" and month != "August" and month != "September" and month != "October" and
   ; month != "December" and month != "January")[

   ; if count bushplot with [count turtles with [shape = "box"] > 0
   ;   and count turtles with [shape = "triangle"] > 0
   ; ] = 0 [

   ;   if mn = 0
    ;  [
   ;     set mn 1
   ;     let nbp count bushplot
   ;     set nbp nbp / 3
   ;     create-turtles nbp [
   ;       set shape "triangle"
   ;       set color 35
   ;       set typo "manure"
   ;       move-to one-of bushplot with [count turtles-here with [shape = "triangle"] = 0]
    ;    ]
   ;   ]
   ; ]
  ;]

  reproduce gamer animal
  getmanure gamer
  liens farmlab

  ask cow with [grazed = "yes"] [set grazed ""]
end

to grazeresidue [gamer animal]
  let farmlab item 0 [label] of farmers with [player =  gamer]
  let farmpos item 0 [pos] of farmers with [player =  gamer]
  let cow turtles with [shape = animal and canmove = "yes" and farm = farmlab]

     ;;animals movements on agricultural plots
  ask cow with [grazed != "yes"][if any? turtles with [(shape = "star" and open = "yes" and hidden? = false) and
    (farm = farmlab or foreignaccess = "yes")][
    move-to one-of turtles with [(shape = "star" and open = "yes" and hidden? = false) and
    (farm = farmlab or foreignaccess = "yes")]
    ]
  ]


  ask cow with [grazed != "yes"][
    ifelse any? turtles-here with[shape = "star" and open = "yes" and (farm = farmlab or foreignaccess = "yes")][][
      if any? turtles with[shape = "star" and open = "yes" and (farm = farmlab or foreignaccess = "yes") and hidden? = false] [
        move-to one-of cultivplot with [
          count turtles-here with [shape = "star" and open ="yes" and
            (farm = farmlab or foreignaccess = "yes") and hidden? = false] > 0]
      ]
    ]

  ]


  ;;eating residue
  let kil 0
  let kild 0
  ask cow with [grazed != "yes"][
    if any? turtles-here with[shape = "star" and farm = farmlab and hidden? = false] [
      ask turtles-here with[shape = "star" and farm = farmlab and hidden? = false] [
        ifelse (animal = "cow" or animal = "wolf") [
          set kil count turtles-here with [(shape = "cow" or shape ="wolf")]
          set kild count turtles-here with [shape = "star" and farm = farmlab and hidden? = false]
          if kil > kild [set kil kild]
          ask n-of kil turtles-here with[shape = "star" and farm = farmlab and hidden? = false][die]
        ]

        [
          if count turtles-here with [shape = "sheep" and hidden? = false] = 1 [
            ifelse neat = 2 [
              ask one-of turtles-here with[shape = "star" and farm = farmlab and hidden? = false and neat = 2][die]
            ]

            [ set neat neat + 1]
          ]
          if count turtles-here with [shape = "sheep" ] >= 2 [
            set kil count turtles-here with [shape = "sheep" ]
            set kild count turtles-here with [shape = "star" and farm = farmlab and hidden? = false]
            if (kil / 2) > kild [set kil kild]
            ask n-of ceiling (kil / 2) turtles-here with[shape = "star" and farm = farmlab and hidden? = false] [die]
          ]
        ]
      ]
      set energy energy + 1
      set hunger 0
      set grazed "yes"
    ]
  ]

end

to livupdate [gamer]

  ask farmers with [player = gamer][
    set ncow count out-link-neighbors with[shape = "cow" and canmove = "yes" and [pcolor] of patch-here != white]
    set nsrum count out-link-neighbors with[shape = "sheep" and canmove = "yes" and [pcolor] of patch-here != white]
    set ndonkey count out-link-neighbors with[shape = "wolf" and canmove = "yes" and [pcolor] of patch-here != white]
    set npoultry count out-link-neighbors with[shape = "bird"] - 1; remove the ficitve one
    set ngrain count out-link-neighbors with[shape = "cylinder" and [pcolor] of patch-here != white]
    set nconc count out-link-neighbors with[typo = "conc"] - 1; remove the ficitve one
                                                              ;ifelse ticks > 1 [set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1]; remove the ficitve one
                                                              ;[ifelse nf < 1 [set nfertilizer nfertilizer + count out-link-neighbors with[typo = "fertilizer"] - 1 set nf nf + 1]
                                                              ;  [set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1]
                                                              ;]
    set nfertilizer count out-link-neighbors with[typo = "fertilizer"] - 1
    if ticks > 0 [
      set nmanure count out-link-neighbors with[typo = "manure"] - 1]
  ]
end

to directfeed [gamer]
  let farmlab item 0 [farm] of farmers with [player = gamer]
  if (count turtles with [(shape = "cow" or shape = "sheep" or shape = "wolf") and hunger > 0 and grazed != "yes" and farm = farmlab] > 0) [
    ask farmers with [player = gamer][
      set forage count out-link-neighbors with [shape = "star" and hidden? = true and open = "yes"]
      let fourrage forage

      ;;case of animal with 0 energy, cow > wolf > srum
      emergencyfeed gamer "cow"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "wolf"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "sheep"

      if forage < 0 [set forage 0]
      let reste fourrage - forage
      let tofeed1 count out-link-neighbors with [(shape ="cow" or shape = "wolf") and canmove = "yes" and grazed = ""]
      let tofeed2 count out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed = ""]
      let ration (1 * tofeed1 + .5 * tofeed2);1 star =1cow/donkey = 2 small rum

      ifelse forage < ration [
        set ration forage if ration > tofeed1 [set ration tofeed1];;ration should be <= ncow + ndonkey (tofeed1)
        set tofeed2 forage - tofeed1 if tofeed2 < 0 [set tofeed2 0];; the remaining ration goes to srum

        ask n-of ration out-link-neighbors with [(shape ="cow" or shape = "wolf") and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]

        ask n-of tofeed2 out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]

      ][
        ask n-of tofeed1 out-link-neighbors with [(shape ="cow" or shape = "wolf") and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]

        ask n-of tofeed2 out-link-neighbors with [shape = "sheep" and canmove = "yes" and grazed = ""][
          set energy energy + 1
          set hunger 0
          set grazed "yes"
        ]
      ]
      ;;diminish forage stock
      set ration ration + reste
      ask n-of (ceiling ration) out-link-neighbors with [shape = "star" and hidden? = true][
        die
      ]
    ]

  ]

end

to emergencyfeed [gamer animal]
  let fac 0
  let frg forage
  ifelse animal = "sheep" [set fac 2][set fac 1]
  ask farmers with [player = gamer][
  let riskyc count out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0]
    if riskyc > 0 [ifelse (forage * fac) > riskyc [
      ask n-of riskyc out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0][
        set energy energy + 1
        set hunger 0
        set grazed "yes"
        set forage forage - floor riskyc / fac
      ]]
          [ask n-of (forage * fac) out-link-neighbors with [shape = animal and canmove = "yes" and hunger > 0][
        set energy energy + 1
        set hunger 0
        set grazed "yes"
        set forage 0
      ]]
     ; ask n-of (ceiling frg - forage) out-link-neighbors with [shape = "star" and hidden? = true][
      ;  die
     ; ]
  ]]
end

to concfeed [gamer]
  let app "no"; apply conc feed or not

  if gamer = "player 1" [
    ifelse feedconc_p1 = "yes_1"[
      set app "yes"]
    [set app "no"]
  ]

  if gamer = "player 2" [
    ifelse feedconc_p2 = "yes_1"[
      set app "yes"]
    [set app "no"]
  ]

  if gamer = "player 3" [
    ifelse feedconc_p3 = "yes_3"[
      set app "yes"]
    [set app "no"]
  ]

  if gamer = "player 4" [
    ifelse feedconc_p3 = "yes_4"[
      set app "yes"]
    [set app "no"]
  ]

  if app = "yes" [

    ask farmers with [player = gamer][
      let cow out-link-neighbors with [shape = "cow" and canmove = "yes"]
      set forage nconc * 2 ;;concentrate = double effect of residue
      let fourrage forage
      let rest 0

      ;;case of animal with 0 energy, cow > wolf > srum
      emergencyfeed gamer "cow"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "wolf"
      if forage < 0 [set forage 0]
      emergencyfeed gamer "sheep"

      if forage < 0 [set forage 0]
      let nanim forage

      ifelse count cow > 0 [
        if forage >= count cow [set nanim count cow set rest forage - nanim]
        ask n-of nanim cow [
          set energy energy + 1 ; 1 unit conc = 1 cattle for 1 month
        ]
      ][
        let srum out-link-neighbors with [shape = "sheep" and canmove = "yes"]
        set nanim forage * 2;1 unit conc = 2 sheep for 1 month
        if nanim >= count srum [set nanim count srum set rest (forage * 2 - nanim) / 2]
        ask n-of nanim srum [
          set energy energy + 1
        ]
      ]
      ask n-of (ceiling fourrage - forage) out-link-neighbors with [typo = "conc"][
       die
      ]
     ; set nconc rest
    ]

  ]
end

to getmanure [gamer]

  ask farmers with [player = gamer][
    ask patches with [pcolor = rgb 0 255 0][
      let animher count turtles-here with [shape = "cow" and canmove = "yes"]
      set animhere fput animher animhere
    ]
  ]

  if month = "June" [
   ask patches with [pcolor = rgb 0 255 0][
      let chargeanim sum animhere
      let manuregain floor (chargeanim / 4)
      sprout manuregain [
        set typo "manure"
        set shape "triangle"
        set farm item 0 [farm] of farmers with [pos = read-from-string [plabel] of patch-here]
        set color 35
        set size .5
      ]
    ]
  ]
end

to foreignresidue [gamer]
  ;;other farms access residue left on field
  if gamer = "player 1" [set accessresid open_field1?]
  if gamer = "player 2" [set accessresid open_field2?]
  if gamer = "player 3" [set accessresid open_field3?]
  if gamer = "player 4" [set accessresid open_field4?]
  if any? joueurs with [idplay = gamer][
    set accessresid item 0 [open_field?] of joueurs with [idplay = gamer]];;player has priority on game master
  ask farmers with [player = gamer][
    ask out-link-neighbors with [typo = "residue" and shape = "star"][
      if accessresid = true [set foreignaccess "no"]
    ]
  ]
end

to liens [ferme]
   ask farmers with [farm = ferme] [
        create-biom_owner-to other turtles with [farm = ferme][
          set color red hide-link
        ]
  ]
end

to farmlink
  ask farmers [
    create-biom_transfer-to other farmers[
          set color blue hide-link
        ]
  ]

end


to biomfluxes [sender receiver biomsent biomreceiv]
  liens "1" liens "2" liens "3" liens "4"

  let biomsown 0;biomass own by sender
  let biomrown 0;biomass own by receiver

  if biomsent = "concentrate" [set biomsent "conc"]
  if biomsent = "small ruminant" [set biomsent "srum"]
  if biomreceiv = "concentrate" [set biomreceiv "conc"]
  if biomreceiv = "small ruminant" [set biomreceiv "srum"]

  ifelse biomsent != "money"[
    ask farmers with [player = sender][
      ifelse biomsent != "conc" and biomsent != "poultry" and biomsent != "manure"[
        set biomsown count out-link-neighbors with [typo = biomsent and [pcolor] of patch-here != white ]]
        [set biomsown count out-link-neighbors with [typo = biomsent]]
      ]
    ][set biomsown item 0[onfarm_inc] of farmers with [player = sender ] + item 0[offfarm_inc] of farmers with [player = sender ]]

    ifelse biomreceiv != "money" [
      ask farmers with [player = receiver][
        ifelse biomreceiv != "conc" and biomreceiv != "poultry" and biomreceiv != "manure"[
        set biomrown count out-link-neighbors with [typo = biomreceiv and [pcolor] of patch-here != white ]]
          [set biomrown count out-link-neighbors with [typo = biomreceiv]]
        ]
      ][set biomrown item 0[onfarm_inc] of farmers with [player = receiver] + item 0[offfarm_inc] of farmers with [player = receiver]]

  if biomsent = "poultry" [set biomsown biomsown - 1]; remove the fictive one
  if biomreceiv = "poultry" [set biomrown biomrown - 1]
      ;PM:think of case it is a gift
  if biomass_sent_amount > biomsown [user-message "Sender: you cannot send more biomass than you own. Please try again" stop]
  if biomass_in_amount > biomrown [user-message "Receiver: you cannot send more biomass than you own. Please try again" stop]

  ;;biomass exchange
  biomexchange sender receiver biomsent biomreceiv

  ask biom_owner [die]
  liens "1" liens "2" liens "3" liens "4"
  livupdate sender
  livupdate receiver

end

to biomexchange [sender receiver biomsent biomreceiv]
  let biom_out biomass_sent_amount
  let biom_in biomass_in_amount
  ask farmers with [player = sender][
    ifelse biomsent != "money"[
      ifelse biomsent != "conc" and biomsent != "poultry"  and biomsent != "manure"[
      ask n-of biom_out out-link-neighbors with [typo = biomsent and [pcolor] of patch-here != white][
        set farm item 0[farm] of farmers with [player = receiver]
      ]][
        ask n-of biom_out out-link-neighbors with [typo = biomsent][
        set farm item 0[farm] of farmers with [player = receiver]
      ]]
    ][
     ifelse  (onfarm_inc - biom_out) >= 0[
        set onfarm_inc onfarm_inc - biom_out]
      [set offfarm_inc offfarm_inc - biom_out + onfarm_inc set onfarm_inc 0]
      ask farmers with [player = receiver][set onfarm_inc onfarm_inc + biom_out]
    ]
  ]


  ask farmers with [player = receiver][
    ifelse biomreceiv != "money"[
        ifelse biomreceiv != "conc" and biomreceiv != "poultry" and biomreceiv != "manure"[
      ask n-of biom_in out-link-neighbors with [typo = biomreceiv and [pcolor] of patch-here != white][
        set farm item 0[farm] of farmers with [player = sender]
      ]][
          ask n-of biom_in out-link-neighbors with [typo = biomreceiv][
        set farm item 0[farm] of farmers with [player = sender]
        ]]
    ][
      ifelse  (onfarm_inc - biom_in) >= 0[
        set onfarm_inc onfarm_inc - biom_in]
      [set offfarm_inc offfarm_inc - biom_in + onfarm_inc set onfarm_inc 0 ]
      ask farmers with [player = sender][set onfarm_inc onfarm_inc + biom_in]
    ]
  ]
end


to market-sell [gamer biomass weigh]
  let bonus 0;for livestock in dec, apr, june
  let bonus2 0;for grain in april-june
  let bonus3 0; for tricycle
  if biomass = "tricycle" [set bonus3 2]
  if month = "December" or month = "April" or month = "June" [set bonus 1]
  if month = "April" or month = "May" or month = "June" [set bonus2 1]
  let etat ""
  let qsell 0
  if biomass = "concentrate" [set biomass "conc"]
  if biomass = "small ruminant" [set biomass "srum"]

  ifelse biomass != "cart" and biomass != "tricyle" and biomass != "poultry" [
    ask farmers with [player = gamer][
      set qsell count out-link-neighbors with [typo = biomass and [pcolor] of patch-here != white and state = weigh]]
  ]
  [ifelse biomass = "cart" [set qsell item 0[ncart] of farmers with [player = gamer]][set qsell item 0[ntricycle] of farmers with [player = gamer]]]

  if biomass = "poultry" [ifelse sell_how_much < 10 and sell_how_much != 0[user-message "You cannot sell less than 10 poultry" stop]
    [set qsell item 0[npoultry] of farmers with [player = gamer]]
  ]

  if biomass = "fertilizer" [set qsell item 0[nfertilizer] of farmers with [player = gamer]]
  if biomass = "conc" [set qsell item 0[nconc] of farmers with [player = gamer]]
  if biomass = "grain" [set qsell item 0[ngrain] of farmers with [player = gamer]]
  if biomass = "manure" [set qsell item 0[nmanure] of farmers with [player = gamer]]

  if sell_how_much > qsell [user-message "You cannot sell more than you have" stop]
  ifelse biomass != "cart" and biomass != "tricycle" and biomass != "poultry"
  and biomass != "tricycle" and biomass != "fertilizer" and biomass != "conc" and biomass != "manure"[
    ask farmers with [player = gamer][
      ask n-of sell_how_much out-link-neighbors with [typo = biomass and [pcolor] of patch-here != white and state = weigh][
        set etat state
        die
      ]
      if biomass = "cattle" [
        if etat = "skinny"[set onfarm_inc onfarm_inc + (6 + bonus) * sell_how_much]; * sell_how_much
        if etat = "medium"[set onfarm_inc onfarm_inc + (8 + bonus) * sell_how_much]
        if etat = "fat"[set onfarm_inc onfarm_inc + (10 + bonus) * sell_how_much]
      ]
      if biomass = "srum" [
        if etat = "skinny"[set onfarm_inc onfarm_inc + (1 + bonus) * sell_how_much]
        if etat = "medium"[set onfarm_inc onfarm_inc + (2 + bonus) * sell_how_much]
        if etat = "fat"[set onfarm_inc onfarm_inc + (3 + bonus) * sell_how_much]
      ]
      if biomass = "donkey" [
        if etat = "skinny"[set onfarm_inc onfarm_inc + (3 + bonus) * sell_how_much]
        if etat = "medium"[set onfarm_inc onfarm_inc + (5 + bonus) * sell_how_much]
        if etat = "fat"[set onfarm_inc onfarm_inc + (6 + bonus) * sell_how_much]
      ]
      if biomass = "residue" or biomass = "grain" [set onfarm_inc onfarm_inc + (2 + bonus2) * sell_how_much]
    ]
  ][
    ask farmers with [player = gamer][
      ifelse biomass = "cart" or biomass = "tricycle" [
        set onfarm_inc onfarm_inc + (6 + bonus3) * sell_how_much]
      [if biomass = "poultry"[set onfarm_inc onfarm_inc + (1 + bonus) * (sell_how_much / 10)];1unit of money = 10 poultry
       if biomass = "fertilizer" [set onfarm_inc onfarm_inc + 1 * sell_how_much]
        if biomass = "conc" [set onfarm_inc onfarm_inc + (2 + bonus2) * sell_how_much]
        if biomass = "manure" [set onfarm_inc onfarm_inc + (2 + bonus2) * sell_how_much]
      ]

      ask n-of sell_how_much out-link-neighbors with [typo = biomass][
        die
      ]

  ]]
end

to market-buy [gamer biomass]
  let bonus 0;for livestock in dec, apr, june
  let bonus2 0;for grain in april-june
  let bonus3 0; for tricycle
  if biomass = "tricycle" [set bonus3 2]
  if month = "December" or month = "April" or month = "June" [set bonus 1]
  if month = "April" or month = "May" or month = "June" [set bonus2 1]
  let etat ""
  let qbuy 0
  ask patches with [plabel = ""][set plabel "99"]
  if biomass = "concentrate" [set biomass "conc"]
  if biomass = "small ruminant" [set biomass "srum"]

  ifelse (biomass != "cart" or biomass != "tricycle")[
    ask farmers with [player = gamer][
      let inc onfarm_inc + offfarm_inc
      if biomass = "cattle" [
        set qbuy (6 + bonus) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

        if biomass = "srum" [
        set qbuy (1 + bonus) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

        if biomass = "donkey" [
        set qbuy (3 + bonus) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      if biomass = "residue" or biomass = "manure" or biomass = "grain" or biomass = "conc"[
        set qbuy (2 + bonus2) * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      if biomass = "poultry" [
        set qbuy (1 + bonus) * (buy_how_much / 10)
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      if biomass = "fertilizer" [
        set qbuy 1 * buy_how_much
        ifelse inc < qbuy [user-message "You do not have enough money" stop] [
          ifelse qbuy > onfarm_inc[
            set offfarm_inc inc - qbuy
            set onfarm_inc 0
          ][set onfarm_inc onfarm_inc - qbuy]
        ]
      ]

      ask one-of turtles with [typo = biomass][
        hatch buy_how_much[
          if biomass = "cattle" or biomass = "srum" or biomass = "donkey"[set state "skinny"]
          if biomass = "residue" [set shape "star" set hidden? true]
          if biomass = "conc" [set shape "lightning"]
          set farm item 0 [farm] of farmers with [player = gamer]
          if biomass != "poultry" and biomass != "conc"[set canmove "yes"
            move-to one-of patches with [(read-from-string plabel) = (item 0[pos] of farmers with [player = gamer])]
            if any? patches with [(read-from-string plabel) = (item 0[pos] of farmers with [player = gamer]) and
              count turtles-here < 2]
            [move-to one-of patches with [(read-from-string plabel) = (item 0[pos] of farmers with [player = gamer]) and
              count turtles-here < 2]]

            if any? patches with [(read-from-string plabel) = (item 0[pos] of farmers with [player = gamer]) and
              count turtles-here = 0]
            [move-to one-of patches with [(read-from-string plabel) = (item 0[pos] of farmers with [player = gamer]) and
              count turtles-here = 0]]

          ]
          if biomass = "fertilizer" [set color 96 set size .75 set heading one-of (range 0 360 45)];;used in sow
          if biomass = "manure" [set color 36 set size .75 set heading one-of (range 0 360 45)]
          liens item 0 [farm] of farmers with [player = gamer]
        ]
      ]
      if ticks = 0[
        if biomass = "manure" [set nmanure nmanure + buy_how_much]
        if biomass = "fertilizer" [set nfertilizer nfertilizer + buy_how_much]
      ]
    ]
  ][
    ask farmers with [player = gamer][
      let inc onfarm_inc + offfarm_inc
      set qbuy (6 + bonus3) * buy_how_much
      ifelse inc < qbuy [user-message "You do not have enough money" stop] [
        ifelse qbuy > onfarm_inc[
          set offfarm_inc inc - qbuy
          set onfarm_inc 0
        ][set onfarm_inc onfarm_inc - qbuy]
  ]
      ask one-of out-link-neighbors with [typo = biomass][
      hatch buy_how_much[
        set farm item 0 [farm] of farmers with [player = gamer]
        liens item 0 [farm] of farmers with [player = gamer]
      ]
    ]]
  ]
  ask patches with [plabel = "99"][set plabel ""]
end

to reproduce [gamer animal]
  ;;livestock reproduction, aging and dying
  let anima animal
  if anima = "wolf" [set anima "donkey"]
  ask farmers with [player = gamer][
    if day > 1 [
      ask out-link-neighbors with [shape = animal and canmove = "yes" and grazed != "yes"][
        set hunger hunger + 1
        set energy energy - 2

    ]]
  ask out-link-neighbors with [shape = animal and canmove = "yes"][
    if hunger >= 2 [
      set warn 1
        show (word gamer " you have a lost one or more "
          anima " in your herd!")
      die

    ]

      if energy <= 10 [set state "skinny"]
      if energy > 10 and energy <= 16 [set state "medium"]
      if energy > 16 [set state "fat" set energy 17]

    if energy > 14 and repro != "yes"[
     if random 101 >= 80 [
       hatch 1
        set repro "yes"
        set warn warn + 1
        show (word gamer " you have a "
          anima " newborn " " in your herd!");;20% of chance to reproduce
      ]
    ]
  ]
]
  liens "1" liens "2" liens "3" liens "4"
end

to feedfamily [gamer]
  ;;1 unit of grain = 2 persons for 12 months
  let nfeed 0
  let ration (item 0 [ngrain] of farmers with [player = gamer]) * 2
  ifelse (item 0 [feedfam] of farmers with [player = gamer]) = 0 [
  set nfeed item 0 [family_size] of farmers with [player = gamer]]
  [set nfeed item 0 [food_unsecure] of farmers with [player = gamer]]

    let foodreq ration - nfeed
  ask farmers with [player = gamer][
    ifelse foodreq < 0 [set food_unsecure abs foodreq set ngrain 0
      ask out-link-neighbors with [shape = "cylinder"][die]
    ]
    [set food_unsecure 0 set ngrain floor (ngrain - (nfeed / 2))
    ask n-of ceiling (nfeed / 2) out-link-neighbors with [shape = "cylinder"][die]
    ]
    set feedfam 1
]
end
@#$#@#$#@
GRAPHICS-WINDOW
456
10
864
419
-1
-1
30.8
1
10
1
1
1
0
0
0
1
0
12
-12
0
0
0
1
ticks
30.0

BUTTON
28
43
95
76
set-up
set-up\nenvironment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
2
150
94
195
player1pos
player1pos
1 2 3 4
0

CHOOSER
2
206
94
251
player2pos
player2pos
1 2 3 4
1

CHOOSER
104
151
196
196
player3pos
player3pos
1 2 3 4
2

CHOOSER
104
207
196
252
player4pos
player4pos
1 2 3 4
3

TEXTBOX
28
99
145
139
Players position on the board
16
0.0
1

TEXTBOX
33
266
120
286
Player types
16
0.0
1

CHOOSER
4
294
96
339
player1type
player1type
"SOC" "SOL" "MOD" "LCL"
0

CHOOSER
101
295
193
340
player2type
player2type
"SOC" "SOL" "MOD" "LCL"
2

CHOOSER
4
345
96
390
player3type
player3type
"SOC" "SOL" "MOD" "LCL"
1

CHOOSER
101
345
193
390
player4type
player4type
"SOC" "SOL" "MOD" "LCL"
3

MONITOR
86
420
173
465
Month
month
17
1
11

TEXTBOX
923
10
1019
30
Player 1 stats
16
0.0
1

MONITOR
867
35
924
80
cattle
item 0 [ncow] of turtles with [player = \"player 1\" and shape = \"person farmer\"]
17
1
11

MONITOR
925
35
989
80
small rum
item 0 [nsrum] of turtles with [player = \"player 1\" and shape = \"person farmer\"]
17
1
11

MONITOR
990
35
1047
80
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1049
35
1099
80
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1152
35
1202
80
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1204
35
1254
80
cart
item 0 [ncart] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1100
35
1150
80
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1257
35
1307
80
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 1\" and\nshape = \"person farmer\"]
17
1
11

MONITOR
867
84
938
129
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1111
85
1168
130
conc
item 0 [nconc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1171
85
1228
130
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1283
84
1333
129
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1231
84
1282
129
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 1\" and \nshape = \"person farmer\"]
17
1
11

BUTTON
534
428
812
461
Next step
if ticks = 0 [plot-pen-down]\nif month = \"July\" [sow]\ngrow [0]\nharvest presid1 \"player 1\"\nharvest presid2 \"player 2\"\nharvest presid3 \"player 3\"\nharvest presid4 \"player 4\"\nfeedfamily \"player 1\"\nfeedfamily \"player 2\"\nfeedfamily \"player 3\"\nfeedfamily \"player 4\"\nset buy_how_much 0\nset sell_how_much 0\nset biomass_sent_amount 0\nset biomass_in_amount 0\nnextmonth
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
228
54
320
87
presid1
presid1
0
100
49.0
1
1
NIL
HORIZONTAL

SLIDER
327
54
420
87
presid2
presid2
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
227
163
319
196
presid3
presid3
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
327
163
419
196
presid4
presid4
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
207
13
439
32
Proportion of residue left on field
14
0.0
1

TEXTBOX
254
35
308
53
Player 1
12
0.0
1

TEXTBOX
350
34
396
52
Player 2
12
0.0
1

TEXTBOX
254
143
301
161
Player 3
12
0.0
1

TEXTBOX
347
143
391
161
Player 4
12
0.0
1

MONITOR
1019
85
1106
130
residue on field
count turtles\nwith [farm = \"1\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
12
470
100
515
Season
saison
17
1
11

MONITOR
940
84
1014
129
stock residue
count turtles\nwith [farm = \"1\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

TEXTBOX
925
131
1024
151
Player 2 stats
16
0.0
1

MONITOR
867
154
917
199
cattle
item 0 [ncow] of turtles with [player = \"player 2\" and shape = \"person farmer\"]
17
1
11

MONITOR
919
153
974
198
small rum
item 0 [nsrum] of turtles with [player = \"player 2\" and shape = \"person farmer\"]
17
1
11

MONITOR
976
153
1026
198
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1028
153
1078
198
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1080
153
1130
198
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1132
153
1190
198
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1194
153
1246
198
cart
item 0 [ncart] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1250
152
1307
197
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
868
201
942
246
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
944
201
1020
246
stock residue
count turtles\nwith [farm = \"2\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

MONITOR
1021
202
1108
247
residue on field
count turtles\nwith [farm = \"2\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
1110
202
1160
247
conc
item 0 [nconc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1163
202
1213
247
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1215
202
1265
247
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1269
201
1319
246
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 2\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
931
252
1033
272
Player 3 stats
16
0.0
1

MONITOR
868
277
918
322
cattle
item 0 [ncow] of turtles with [player = \"player 3\" and shape = \"person farmer\"]
17
1
11

MONITOR
920
277
976
322
small rum
item 0 [nsrum] of turtles with [player = \"player 3\" and shape = \"person farmer\"]
17
1
11

MONITOR
979
277
1036
322
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1039
277
1089
322
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1091
277
1141
322
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1143
277
1193
322
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1196
277
1246
322
cart
item 0 [ncart] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1249
277
1299
322
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
868
324
939
369
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
941
324
1017
369
stock residue
count turtles\nwith [farm = \"3\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

MONITOR
1019
324
1103
369
residue on field
count turtles\nwith [farm = \"3\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
1106
324
1156
369
conc
item 0 [nconc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1159
324
1209
369
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1212
325
1262
370
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1264
324
1314
369
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 3\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
933
376
1032
396
Player 4 stats
16
0.0
1

MONITOR
870
397
920
442
cattle
item 0 [ncow] of turtles with [player = \"player 4\" and shape = \"person farmer\"]
17
1
11

MONITOR
923
397
979
442
small rum
item 0 [nsrum] of turtles with [player = \"player 4\" and shape = \"person farmer\"]
17
1
11

MONITOR
982
397
1032
442
poultry
item 0 [npoultry] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1036
396
1086
441
donkey
item 0 [ndonkey] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1090
395
1140
440
tricycle
item 0 [ntricycle] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1143
395
1193
440
fertilizer
item 0 [nfertilizer] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1196
395
1246
440
cart
item 0 [ncart] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1248
395
1298
440
grain
item 0 [ngrain] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
870
445
942
490
residue harv
item 0 [nresidue] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
944
445
1020
490
stock residue
count turtles\nwith [farm = \"4\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]
17
1
11

MONITOR
1021
445
1109
490
residue on field
count turtles\nwith [farm = \"4\" and\n hidden? = false and shape = \"star\"]
17
1
11

MONITOR
1112
445
1162
490
conc
item 0 [nconc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1166
445
1216
490
manure
item 0 [nmanure] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1219
445
1269
490
off farm
item 0 [offfarm_inc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

MONITOR
1272
446
1322
491
on farm
item 0 [onfarm_inc] of turtles with [\nplayer = \"player 4\" and \nshape = \"person farmer\"]
17
1
11

TEXTBOX
270
252
399
292
Biomass fluxes between players
16
0.0
1

TEXTBOX
240
292
283
311
Send
14
0.0
1

TEXTBOX
365
290
429
309
Receive
14
0.0
1

CHOOSER
220
313
312
358
biomass_sender
biomass_sender
"player 1" "player 2" "player 3" "player 4"
1

CHOOSER
338
314
430
359
biomass_receiver
biomass_receiver
"player 1" "player 2" "player 3" "player 4"
2

CHOOSER
220
360
312
405
biomass_sent
biomass_sent
"residue" "manure" "grain" "concentrate" "cattle" "small ruminant" "donkey" "poultry" "money"
0

CHOOSER
337
362
447
407
biomass_counterpart
biomass_counterpart
"residue" "manure" "grain" "concentrate" "cattle" "small ruminant" "donkey" "poultry" "money"
8

INPUTBOX
205
408
323
468
biomass_sent_amount
0.0
1
0
Number

INPUTBOX
338
408
447
468
biomass_in_amount
0.0
1
0
Number

CHOOSER
127
588
219
633
buy
buy
"residue" "manure" "grain" "concentrate" "cattle" "small ruminant" "donkey" "poultry" "fertilizer" "cart" "tricyle"
8

CHOOSER
334
587
426
632
sell
sell
"residue" "manure" "grain" "concentrate" "cattle" "srum" "donkey" "poultry" "fertilizer" "cart" "tricyle"
1

INPUTBOX
222
590
309
650
buy_how_much
0.0
1
0
Number

INPUTBOX
429
589
518
649
sell_how_much
0.0
1
0
Number

TEXTBOX
295
520
352
540
Market
16
0.0
1

CHOOSER
217
540
309
585
buyer
buyer
"player 1" "player 2" "player 3" "player 4"
3

CHOOSER
334
539
426
584
seller
seller
"player 1" "player 2" "player 3" "player 4"
1

CHOOSER
580
487
672
532
feedconc_p1
feedconc_p1
"yes_1" "no_1"
0

CHOOSER
675
487
767
532
feedconc_p2
feedconc_p2
"yes_2" "no_2"
0

CHOOSER
580
534
672
579
feedconc_p3
feedconc_p3
"yes_3" "no_3"
0

CHOOSER
676
534
768
579
feedconc_p4
feedconc_p4
"yes_4" "no_4"
0

BUTTON
259
473
382
506
Apply biomass transfer
biomfluxes biomass_sender biomass_receiver biomass_sent biomass_counterpart\nset biomass_sent_amount 0\nset biomass_in_amount 0
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
438
545
508
578
Market
market-sell seller sell weight\nlivupdate seller\nmarket-buy buyer buy\nlivupdate buyer\nset buy_how_much 0\nset sell_how_much 0
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
108
471
170
516
Warning
warn
17
1
11

BUTTON
877
547
941
580
feed family
feedfamily family\n;livupdate family
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
861
496
953
541
family
family
"player 1" "player 2" "player 3" "player 4"
3

MONITOR
1013
528
1063
573
Player 1
item 0 [food_unsecure] of farmers with [player = \"player 1\"]
17
1
11

MONITOR
1071
528
1121
573
Player 2
item 0 [food_unsecure] of farmers with [player = \"player 2\"]
17
1
11

MONITOR
1128
527
1178
572
Player 3
item 0 [food_unsecure] of farmers with [player = \"player 3\"]
17
1
11

MONITOR
1183
527
1233
572
Player 4
item 0 [food_unsecure] of farmers with [player = \"player 4\"]
17
1
11

TEXTBOX
1067
501
1180
520
Food unsecure
14
0.0
1

CHOOSER
334
634
426
679
weight
weight
"skinny" "medium" "fat" 0
3

MONITOR
22
421
79
466
Year
year
17
1
11

MONITOR
1322
154
1387
199
risky cow
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1322
36
1387
81
risky cow
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1389
35
1459
80
risky srum
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1358
84
1441
129
risky donkey
count turtles with [farm = \"1\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1388
153
1458
198
risky srum
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1344
202
1426
247
risky donkey
count turtles with [farm = \"2\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1322
278
1387
323
risky cow
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1386
278
1454
323
risky srum
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1352
326
1432
371
risky donkey
count turtles with [farm = \"3\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1320
399
1385
444
risky cow
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"cow\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1387
398
1454
443
risky srum
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"sheep\" and \n[pcolor] of patch-here != white\n]
17
1
11

MONITOR
1354
447
1433
492
risky donkey
count turtles with [farm = \"4\" and\nhunger > 0 and shape = \"wolf\" and \n[pcolor] of patch-here != white\n]
17
1
11

BUTTON
99
44
162
77
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

PLOT
1486
37
1719
210
residue left on field
ticks
amount of residue
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "plot count turtles\nwith [farm = \"1\" and\n hidden? = false and shape = \"star\"]"
"player 2" 1.0 0 -1184463 true "" "plot count turtles\nwith [farm = \"2\" and\n hidden? = false and shape = \"star\"]"
"player 3" 1.0 0 -12087248 true "" "plot count turtles\nwith [farm = \"3\" and\n hidden? = false and shape = \"star\"]"
"player 4" 1.0 0 -955883 true "" "plot count turtles\nwith [farm = \"4\" and\n hidden? = false and shape = \"star\"]"

PLOT
1719
36
1952
211
residue stocked
ticks
amount of residue
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "plot count turtles\nwith [farm = \"1\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"
"player 2" 1.0 0 -1184463 true "" "plot count turtles\nwith [farm = \"2\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"
"player 3" 1.0 0 -14439633 true "" "plot count turtles\nwith [farm = \"3\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"
"player 4" 1.0 0 -955883 true "" "plot count turtles\nwith [farm = \"4\" and\n hidden? = true and shape = \"star\"\n and open = \"yes\"\n ]"

PLOT
1487
213
1722
390
cattle
ticks
Number of animals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "plot item 0 [ncow] of turtles\nwith [farm = \"1\" and shape = \"person farmer\"]"
"player 2" 1.0 0 -1184463 true "" "plot item 0 [ncow] of turtles\nwith [farm = \"2\" and shape = \"person farmer\"]"
"player 3" 1.0 0 -14439633 true "" "plot item 0 [ncow] of turtles\nwith [farm = \"3\" and shape = \"person farmer\"]"
"player 4" 1.0 0 -955883 true "" "plot item 0 [ncow] of turtles\nwith [farm = \"4\" and shape = \"person farmer\"]"

PLOT
1724
213
1953
389
small ruminants
ticks
Number of animals
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "plot item 0 [nsrum] of turtles\nwith [farm = \"1\" and shape = \"person farmer\"]"
"player 2" 1.0 0 -1184463 true "" "plot item 0 [nsrum] of turtles\nwith [farm = \"2\" and shape = \"person farmer\"]"
"player 3" 1.0 0 -13840069 true "" "plot item 0 [nsrum] of turtles\nwith [farm = \"3\" and shape = \"person farmer\"]"
"player 4" 1.0 0 -955883 true "" "plot item 0 [nsrum] of turtles\nwith [farm = \"4\" and shape = \"person farmer\"]"

PLOT
1486
393
1723
543
on-farm income
ticks
Income
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "" "plot item 0[onfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 1\"\n]"
"player 2" 1.0 0 -1184463 true "" "plot item 0[onfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 2\"\n]"
"player 3" 1.0 0 -13840069 true "" "plot item 0[onfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 3\"\n]"
"player 4" 1.0 0 -955883 true "" "plot item 0[onfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 4\"\n]"

PLOT
1727
392
1954
542
off-farm income
ticks
Income
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 1\"\n]" "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 1\"\n]"
"player 2" 1.0 0 -1184463 true "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 2\"\n]" "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 2\"\n]"
"player 3" 1.0 0 -13840069 true "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 3\"\n]" "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 3\"\n]"
"player 4" 1.0 0 -955883 true "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 4\"\n]" "plot item 0[offfarm_inc] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 4\"\n]"

PLOT
1623
545
1823
695
grain
ticks
amount of grain
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"player 1" 1.0 0 -13791810 true "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 1\"\n]" "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 1\"\n]"
"player 2" 1.0 0 -1184463 true "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 2\"\n]" "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 2\"\n]"
"player 3" 1.0 0 -13840069 true "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 3\"\n]" "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 3\"\n]"
"player 4" 1.0 0 -955883 true "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 4\"\n]" "plot item 0[ngrain] of turtles with [\nshape = \"person farmer\" and\nplayer = \"player 4\"\n]"

SWITCH
205
90
322
123
open_field1?
open_field1?
1
1
-1000

SWITCH
327
90
445
123
open_field2?
open_field2?
1
1
-1000

SWITCH
205
200
320
233
open_field3?
open_field3?
1
1
-1000

SWITCH
330
202
445
235
open_field4?
open_field4?
1
1
-1000

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

acorn
false
0
Polygon -7500403 true true 146 297 120 285 105 270 75 225 60 180 60 150 75 105 225 105 240 150 240 180 225 225 195 270 180 285 155 297
Polygon -6459832 true false 121 15 136 58 94 53 68 65 46 90 46 105 75 115 234 117 256 105 256 90 239 68 209 57 157 59 136 8
Circle -16777216 false false 223 95 18
Circle -16777216 false false 219 77 18
Circle -16777216 false false 205 88 18
Line -16777216 false 214 68 223 71
Line -16777216 false 223 72 225 78
Line -16777216 false 212 88 207 82
Line -16777216 false 206 82 195 82
Line -16777216 false 197 114 201 107
Line -16777216 false 201 106 193 97
Line -16777216 false 198 66 189 60
Line -16777216 false 176 87 180 80
Line -16777216 false 157 105 161 98
Line -16777216 false 158 65 150 56
Line -16777216 false 180 79 172 70
Line -16777216 false 193 73 197 66
Line -16777216 false 237 82 252 84
Line -16777216 false 249 86 253 97
Line -16777216 false 240 104 252 96

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bird
false
0
Polygon -7500403 true true 135 165 90 270 120 300 180 300 210 270 165 165
Rectangle -7500403 true true 120 105 180 237
Polygon -7500403 true true 135 105 120 75 105 45 121 6 167 8 207 25 257 46 180 75 165 105
Circle -16777216 true false 128 21 42
Polygon -7500403 true true 163 116 194 92 212 86 230 86 250 90 265 98 279 111 290 126 296 143 298 158 298 166 296 183 286 204 272 219 259 227 235 240 241 223 250 207 251 192 245 180 232 168 216 162 200 162 186 166 175 173 171 180
Polygon -7500403 true true 137 116 106 92 88 86 70 86 50 90 35 98 21 111 10 126 4 143 2 158 2 166 4 183 14 204 28 219 41 227 65 240 59 223 50 207 49 192 55 180 68 168 84 162 100 162 114 166 125 173 129 180

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

checker piece 2
false
0
Circle -7500403 true true 60 60 180
Circle -16777216 false false 60 60 180
Circle -7500403 true true 75 45 180
Circle -16777216 false false 83 36 180
Circle -7500403 true true 105 15 180
Circle -16777216 false false 105 15 180

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

coin tails
false
0
Circle -7500403 true true 15 15 270
Circle -16777216 false false 20 17 260
Line -16777216 false 130 92 171 92
Line -16777216 false 123 79 177 79
Rectangle -7500403 true true 57 101 242 133
Rectangle -16777216 false false 45 180 255 195
Rectangle -16777216 false false 75 120 225 135
Polygon -16777216 false false 81 226 70 241 86 248 93 235 89 232 108 243 97 256 118 247 118 265 123 248 142 247 129 253 130 271 145 269 131 259 162 245 153 262 168 268 197 259 177 255 187 245 174 243 193 235 209 251 193 234 225 244 208 227 240 240 222 218
Rectangle -7500403 true true 91 210 222 226
Polygon -16777216 false false 65 70 91 50 136 35 181 35 226 65 246 86 241 65 196 50 166 35 121 50 91 50 61 95 54 80 61 65
Polygon -16777216 false false 90 135 60 135 60 180 90 180 90 135 120 135 120 180 150 180 150 135 180 135 180 180 210 180 210 135 240 135 240 180 210 180 210 135

cow
true
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

drop
true
0
Circle -7500403 true true 73 133 152
Polygon -7500403 true true 219 181 205 152 185 120 174 95 163 64 156 37 149 7 147 166
Polygon -7500403 true true 79 182 95 152 115 120 126 95 137 64 144 37 150 6 154 165

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

lightning
false
0
Polygon -7500403 true true 120 135 90 195 135 195 105 300 225 165 180 165 210 105 165 105 195 0 75 135

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

molecule oxygen
true
0
Circle -7500403 true true 120 75 150
Circle -16777216 false false 120 75 150
Circle -7500403 true true 30 75 150
Circle -16777216 false false 30 75 150

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

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

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
true
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

tile stones
false
0
Polygon -7500403 true true 0 240 45 195 75 180 90 165 90 135 45 120 0 135
Polygon -7500403 true true 300 240 285 210 270 180 270 150 300 135 300 225
Polygon -7500403 true true 225 300 240 270 270 255 285 255 300 285 300 300
Polygon -7500403 true true 0 285 30 300 0 300
Polygon -7500403 true true 225 0 210 15 210 30 255 60 285 45 300 30 300 0
Polygon -7500403 true true 0 30 30 0 0 0
Polygon -7500403 true true 15 30 75 0 180 0 195 30 225 60 210 90 135 60 45 60
Polygon -7500403 true true 0 105 30 105 75 120 105 105 90 75 45 75 0 60
Polygon -7500403 true true 300 60 240 75 255 105 285 120 300 105
Polygon -7500403 true true 120 75 120 105 105 135 105 165 165 150 240 150 255 135 240 105 210 105 180 90 150 75
Polygon -7500403 true true 75 300 135 285 195 300
Polygon -7500403 true true 30 285 75 285 120 270 150 270 150 210 90 195 60 210 15 255
Polygon -7500403 true true 180 285 240 255 255 225 255 195 240 165 195 165 150 165 135 195 165 210 165 255

tile water
false
0
Rectangle -7500403 true true -1 0 299 300
Polygon -1 true false 105 259 180 290 212 299 168 271 103 255 32 221 1 216 35 234
Polygon -1 true false 300 161 248 127 195 107 245 141 300 167
Polygon -1 true false 0 157 45 181 79 194 45 166 0 151
Polygon -1 true false 179 42 105 12 60 0 120 30 180 45 254 77 299 93 254 63
Polygon -1 true false 99 91 50 71 0 57 51 81 165 135
Polygon -1 true false 194 224 258 254 295 261 211 221 144 199

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
true
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
VIEW
366
24
766
424
0
0
0
1
1
1
1
1
0
1
1
1
0
12
-12
0

SLIDER
97
46
269
79
residue_on_field
residue_on_field
0.0
100.0
0
1.0
1
NIL
HORIZONTAL

CHOOSER
73
192
165
237
send_biomass
send_biomass
\"residue\" \"manure\" \"grain\" \"concentrate\" \"cattle\" \"small ruminant\" \"donkey\" \"poultry\" \"money\"
0

INPUTBOX
71
243
168
303
send_how_much
0.0
1
0
Number

CHOOSER
174
193
266
238
send_to
send_to
\"player 1\" \"player 2\" \"player 3\" \"player 4\"
0

BUTTON
177
254
271
287
transfer_biomass
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
92
26
268
52
Proportion of residue to be left on field
10
0.0
1

TEXTBOX
131
168
281
186
Biomass transfer
11
0.0
1

CHOOSER
56
379
148
424
buy_what
buy_what
\"residue\" \"manure\" \"grain\" \"concentrate\" \"cattle\" \"small ruminant\" \"donkey\" \"poultry\" \"fertilizer\" \"cart\" \"tricyle\"
0

INPUTBOX
182
380
256
440
amount_buy
0.0
1
0
Number

CHOOSER
52
439
144
484
sell_what
sell_what
\"residue\" \"manure\" \"grain\" \"concentrate\" \"cattle\" \"small ruminant\" \"donkey\" \"poultry\" \"fertilizer\" \"cart\" \"tricyle\"
0

INPUTBOX
187
455
256
515
amount_sell
0.0
1
0
Number

BUTTON
151
540
221
573
Market
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
164
357
198
375
Market
11
0.0
1

MONITOR
799
92
849
141
nplot
NIL
1
1

MONITOR
854
93
904
142
cattle
NIL
0
1

MONITOR
909
93
959
142
srum
NIL
0
1

MONITOR
1026
92
1083
141
poultry
NIL
0
1

MONITOR
964
93
1021
142
donkey
NIL
0
1

MONITOR
1090
92
1140
141
tricycle
NIL
0
1

MONITOR
1148
91
1198
140
fertilizer
NIL
0
1

MONITOR
1206
91
1256
140
cart
NIL
0
1

MONITOR
1264
91
1314
140
grain
NIL
0
1

MONITOR
800
153
872
202
residue harv
NIL
0
1

MONITOR
877
154
949
203
stock residue
NIL
0
1

MONITOR
956
155
1038
204
residue on field
NIL
0
1

MONITOR
1043
155
1100
204
conc
NIL
0
1

MONITOR
1105
155
1162
204
manure
NIL
0
1

MONITOR
1171
156
1229
205
off farm
NIL
3
1

MONITOR
1238
155
1295
204
on farm
NIL
0
1

MONITOR
930
221
994
270
risky cow
NIL
0
1

MONITOR
1002
221
1071
270
risky srum
NIL
0
1

MONITOR
1078
222
1147
271
risky donkey
NIL
0
1

MONITOR
1002
296
1079
345
food unsecure
NIL
3
1

BUTTON
1001
354
1084
387
feed family
NIL
NIL
1
T
OBSERVER
NIL
NIL

TEXTBOX
997
57
1082
77
Player stats
16
0.0
1

CHOOSER
53
486
145
531
biom_weight
biom_weight
\"skinny\" \"medium\" \"fat\" 0
0

MONITOR
397
622
788
671
warning
NIL
0
1

TEXTBOX
501
453
612
471
Secret message
16
0.0
1

INPUTBOX
452
481
676
616
message text
NIL
1
1
String

BUTTON
682
558
768
591
send message
NIL
NIL
1
T
OBSERVER
NIL
NIL

CHOOSER
679
486
771
531
message who
message who
\"player 1\" \"player 2\" \"player 3\" \"player 4\"
0

MONITOR
920
565
1036
614
pseudo_
NIL
0
1

MONITOR
1056
565
1202
614
name
NIL
0
1

TEXTBOX
1037
544
1052
562
ID
11
0.0
1

MONITOR
1010
481
1093
530
month
NIL
0
1

MONITOR
926
482
983
531
year
NIL
0
1

TEXTBOX
1024
455
1054
473
Time
11
0.0
1

SWITCH
125
94
244
127
open_field?
open_field?
0
1
-1000

TEXTBOX
55
17
76
129
+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
54
128
311
146
*+++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
293
17
312
157
+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
56
10
307
38
*+++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
48
161
63
315
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
48
155
305
173
*++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
49
312
303
330
*++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
294
160
309
314
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
27
354
42
578
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
28
578
339
596
*+++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
27
343
358
361
*+++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
299
353
314
577
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
370
452
385
676
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
372
677
856
695
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
372
444
850
462
*++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
824
454
839
678
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n
11
25.0
1

TEXTBOX
783
58
798
394
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
783
394
1334
422
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
782
44
1332
62
*+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
1324
54
1339
390
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
899
456
914
624
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

TEXTBOX
902
626
1231
644
*++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
902
444
1225
462
*++++++++++++++++++++++++++++++++++++++*
11
25.0
1

TEXTBOX
1212
453
1227
621
+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+\n+
11
25.0
1

MONITOR
1108
481
1207
530
season
NIL
0
1

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
