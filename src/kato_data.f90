!-------------------------------------------------------------------------
! This file is part of the tenstream solver.
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU General Public License as published by
! the Free Software Foundation, either version 3 of the License, or
! (at your option) any later version.
! 
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU General Public License for more details.
! 
! You should have received a copy of the GNU General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.
!
! Copyright (C) 2010-2015  Fabian Jakub, <fabian@jakub.com>
!-------------------------------------------------------------------------

module m_kato_data
      use m_data_parameters, only : ireals,iintegers
implicit none
      private
      public :: get_edirTOA,kato_bands,get_ednTOA

      integer(iintegers),parameter :: kato_bands(32) = (/0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 5 , 0 , 4 , 0 , 5 , 5 , 5 , 5 , 5 , 6 , 5 , 6 , 7 , 5 , 10 , 5 , 6 , 8 , 7 , 3 , 14 /)

real(ireals),allocatable :: edirTOA(:,:),ednTOA(:,:)

      contains
      subroutine setup(z)
        real(ireals),intent(in) :: z
                allocate( ednTOA(32,0:14) )
                allocate( edirTOA(32,0:14) )
                ednTOA=-1
                edirTOA=-1

                !{{{ edn:: TOA=10e3
                if(z.le.dble(10e3)+1) then
                ednTOA( 1 ,0 ) =  0.0
                ednTOA( 10 ,0 ) =  0.252378662763
                ednTOA( 11 ,0 ) =  0.382509141547
                ednTOA( 12 ,0 ) =  0.0647498330998
                ednTOA( 12 ,1 ) =  0.127454505129
                ednTOA( 12 ,2 ) =  0.201947283062
                ednTOA( 12 ,3 ) =  0.185289861015
                ednTOA( 12 ,4 ) =  0.125367249792
                ednTOA( 12 ,5 ) =  0.0674848279194
                ednTOA( 13 ,0 ) =  0.287078742823
                ednTOA( 14 ,0 ) =  0.0581477380403
                ednTOA( 14 ,1 ) =  0.116741568382
                ednTOA( 14 ,2 ) =  0.131355254652
                ednTOA( 14 ,3 ) =  0.12240365955
                ednTOA( 14 ,4 ) =  0.0578686767362
                ednTOA( 15 ,0 ) =  0.152546126852
                ednTOA( 16 ,0 ) =  0.0129007547582
                ednTOA( 16 ,1 ) =  0.0294426625697
                ednTOA( 16 ,2 ) =  0.0387088183372
                ednTOA( 16 ,3 ) =  0.0377347950748
                ednTOA( 16 ,4 ) =  0.0274301684001
                ednTOA( 16 ,5 ) =  0.0121010062509
                ednTOA( 17 ,0 ) =  0.0219951462442
                ednTOA( 17 ,1 ) =  0.0429279612144
                ednTOA( 17 ,2 ) =  0.0532946862101
                ednTOA( 17 ,3 ) =  0.048161948482
                ednTOA( 17 ,4 ) =  0.036232427501
                ednTOA( 17 ,5 ) =  0.0176288947287
                ednTOA( 18 ,0 ) =  0.0224812306254
                ednTOA( 18 ,1 ) =  0.0395144584963
                ednTOA( 18 ,2 ) =  0.0537883235212
                ednTOA( 18 ,3 ) =  0.0502361421224
                ednTOA( 18 ,4 ) =  0.046268637149
                ednTOA( 18 ,5 ) =  0.0117681066914
                ednTOA( 19 ,0 ) =  0.0151298626753
                ednTOA( 19 ,1 ) =  0.0322088621018
                ednTOA( 19 ,2 ) =  0.0407393819369
                ednTOA( 19 ,3 ) =  0.0400695015993
                ednTOA( 19 ,4 ) =  0.0279940651698
                ednTOA( 19 ,5 ) =  0.0134547595515
                ednTOA( 2 ,0 ) =  8.36810385604e-19
                ednTOA( 20 ,0 ) =  0.0109002107012
                ednTOA( 20 ,1 ) =  0.0206859191918
                ednTOA( 20 ,2 ) =  0.0286674318917
                ednTOA( 20 ,3 ) =  0.021681792295
                ednTOA( 20 ,4 ) =  0.015005934276
                ednTOA( 20 ,5 ) =  0.00786460785011
                ednTOA( 21 ,0 ) =  0.0101078665083
                ednTOA( 21 ,1 ) =  0.0178753524661
                ednTOA( 21 ,2 ) =  0.0248424321954
                ednTOA( 21 ,3 ) =  0.0226493254974
                ednTOA( 21 ,4 ) =  0.0247002497274
                ednTOA( 21 ,5 ) =  0.0161659007804
                ednTOA( 21 ,6 ) =  0.0070960679655
                ednTOA( 22 ,0 ) =  0.00576895232726
                ednTOA( 22 ,1 ) =  0.0118097296748
                ednTOA( 22 ,2 ) =  0.0109380000397
                ednTOA( 22 ,3 ) =  0.0148535703303
                ednTOA( 22 ,4 ) =  0.0113810184548
                ednTOA( 22 ,5 ) =  0.00521955562495
                ednTOA( 23 ,0 ) =  0.0036518679746
                ednTOA( 23 ,1 ) =  0.0109560959088
                ednTOA( 23 ,2 ) =  0.0131481270133
                ednTOA( 23 ,3 ) =  0.0155743259146
                ednTOA( 23 ,4 ) =  0.0135263495992
                ednTOA( 23 ,5 ) =  0.00957194475741
                ednTOA( 23 ,6 ) =  0.00439607421523
                ednTOA( 24 ,0 ) =  0.00158675851455
                ednTOA( 24 ,1 ) =  0.00448177386028
                ednTOA( 24 ,2 ) =  0.00772717287737
                ednTOA( 24 ,3 ) =  0.00961362062646
                ednTOA( 24 ,4 ) =  0.00964081907193
                ednTOA( 24 ,5 ) =  0.00559204223744
                ednTOA( 24 ,6 ) =  0.00350473272584
                ednTOA( 24 ,7 ) =  0.00183861880047
                ednTOA( 25 ,0 ) =  0.000323542449941
                ednTOA( 25 ,1 ) =  0.00033749646941
                ednTOA( 25 ,2 ) =  0.00132542027414
                ednTOA( 25 ,3 ) =  0.000441705615404
                ednTOA( 25 ,4 ) =  0.00134880381004
                ednTOA( 25 ,5 ) =  0.000236334551024
                ednTOA( 26 ,0 ) =  0.000313459601692
                ednTOA( 26 ,1 ) =  0.00084870247723
                ednTOA( 26 ,10 ) =  3.41668968792e-05
                ednTOA( 26 ,2 ) =  0.000629726929942
                ednTOA( 26 ,3 ) =  0.000525518040434
                ednTOA( 26 ,4 ) =  0.00175098645667
                ednTOA( 26 ,5 ) =  0.00184433807189
                ednTOA( 26 ,6 ) =  0.000591286787224
                ednTOA( 26 ,7 ) =  0.0013057974208
                ednTOA( 26 ,8 ) =  0.00142640806938
                ednTOA( 26 ,9 ) =  0.000240762254767
                ednTOA( 27 ,0 ) =  6.15466588896e-05
                ednTOA( 27 ,1 ) =  0.000129498885599
                ednTOA( 27 ,2 ) =  0.000496305517057
                ednTOA( 27 ,3 ) =  0.000166904048122
                ednTOA( 27 ,4 ) =  0.000123024117908
                ednTOA( 27 ,5 ) =  6.44644409943e-05
                ednTOA( 28 ,0 ) =  0.000114810503567
                ednTOA( 28 ,1 ) =  0.0
                ednTOA( 28 ,2 ) =  6.7711476147e-05
                ednTOA( 28 ,3 ) =  0.000148236694104
                ednTOA( 28 ,4 ) =  0.000135420557184
                ednTOA( 28 ,5 ) =  0.0
                ednTOA( 28 ,6 ) =  6.88375445395e-05
                ednTOA( 29 ,0 ) =  0.0
                ednTOA( 29 ,1 ) =  0.0
                ednTOA( 29 ,2 ) =  0.0
                ednTOA( 29 ,3 ) =  0.0
                ednTOA( 29 ,4 ) =  0.000384959071478
                ednTOA( 29 ,5 ) =  8.4492114178e-05
                ednTOA( 29 ,6 ) =  0.0
                ednTOA( 29 ,7 ) =  1.09033290669e-06
                ednTOA( 29 ,8 ) =  0.0
                ednTOA( 3 ,0 ) =  0.00151013516503
                ednTOA( 30 ,0 ) =  2.11189180053e-05
                ednTOA( 30 ,1 ) =  0.0
                ednTOA( 30 ,2 ) =  0.0
                ednTOA( 30 ,3 ) =  7.65060207633e-05
                ednTOA( 30 ,4 ) =  0.0
                ednTOA( 30 ,5 ) =  0.0
                ednTOA( 30 ,6 ) =  4.6275564226e-05
                ednTOA( 30 ,7 ) =  0.0
                ednTOA( 31 ,0 ) =  0.0
                ednTOA( 31 ,1 ) =  0.0
                ednTOA( 31 ,2 ) =  0.0
                ednTOA( 31 ,3 ) =  0.0
                ednTOA( 32 ,0 ) =  0.0
                ednTOA( 32 ,1 ) =  0.0
                ednTOA( 32 ,10 ) =  0.0
                ednTOA( 32 ,11 ) =  0.0
                ednTOA( 32 ,12 ) =  0.0
                ednTOA( 32 ,13 ) =  0.0
                ednTOA( 32 ,14 ) =  0.0
                ednTOA( 32 ,2 ) =  0.0
                ednTOA( 32 ,3 ) =  0.0
                ednTOA( 32 ,4 ) =  0.0
                ednTOA( 32 ,5 ) =  0.0
                ednTOA( 32 ,6 ) =  0.0
                ednTOA( 32 ,7 ) =  0.0
                ednTOA( 32 ,8 ) =  0.0
                ednTOA( 32 ,9 ) =  0.0
                ednTOA( 4 ,0 ) =  1.23294771681
                ednTOA( 5 ,0 ) =  3.88718223961
                ednTOA( 6 ,0 ) =  3.80650874535
                ednTOA( 7 ,0 ) =  3.23648239156
                ednTOA( 8 ,0 ) =  3.26044276427
                ednTOA( 9 ,0 ) =  0.692984369278
        endif
        !}}}

        !{{{ edir:: TOA < 10e3
        if(z.le.dble(10e3)+1) then
                edirTOA( 13 , 0 ) =  32.5447957667
                edirTOA( 12 , 3 ) =  15.4095655784
                edirTOA( 12 , 2 ) =  15.3783444536
                edirTOA( 12 , 4 ) =  11.8485903223
                edirTOA( 12 , 0 ) =  5.63942347222
                edirTOA( 12 , 5 ) =  5.63598835181
                edirTOA( 12 , 1 ) =  11.890533558
                edirTOA( 31 , 2 ) =  1.22352933703
                edirTOA( 31 , 3 ) =  0.652441312906
                edirTOA( 31 , 1 ) =  1.22368225982
                edirTOA( 31 , 0 ) =  0.652720450633
                edirTOA( 7 , 0 ) =  73.4544784384
                edirTOA( 24 , 0 ) =  6.24516974258
                edirTOA( 24 , 4 ) =  22.3599826284
                edirTOA( 24 , 1 ) =  13.718872411
                edirTOA( 24 , 5 ) =  19.3051359869
                edirTOA( 24 , 3 ) =  22.3725879051
                edirTOA( 24 , 7 ) =  5.16758249006
                edirTOA( 24 , 2 ) =  19.354608617
                edirTOA( 24 , 6 ) =  13.5410068996
                edirTOA( 9 , 0 ) =  39.729872481
                edirTOA( 23 , 1 ) =  12.0662268956
                edirTOA( 23 , 5 ) =  12.054852145
                edirTOA( 23 , 0 ) =  5.58400572194
                edirTOA( 23 , 4 ) =  16.4600966293
                edirTOA( 23 , 2 ) =  16.4756438589
                edirTOA( 23 , 6 ) =  5.52070052667
                edirTOA( 23 , 3 ) =  18.0230431165
                edirTOA( 22 , 4 ) =  9.2811494005
                edirTOA( 22 , 0 ) =  4.40825914113
                edirTOA( 22 , 5 ) =  4.40804828079
                edirTOA( 22 , 1 ) =  9.28520654551
                edirTOA( 22 , 3 ) =  12.0442047176
                edirTOA( 22 , 2 ) =  12.0442127099
                edirTOA( 6 , 0 ) =  48.441778161
                edirTOA( 21 , 4 ) =  14.1300804884
                edirTOA( 21 , 0 ) =  4.79286811206
                edirTOA( 21 , 5 ) =  10.3446632073
                edirTOA( 21 , 1 ) =  10.3556192514
                edirTOA( 21 , 3 ) =  15.4693183914
                edirTOA( 21 , 6 ) =  4.73071000276
                edirTOA( 21 , 2 ) =  14.1242660909
                edirTOA( 18 , 3 ) =  13.8914483956
                edirTOA( 18 , 2 ) =  13.9020476146
                edirTOA( 18 , 4 ) =  10.7100134302
                edirTOA( 18 , 0 ) =  5.08483355375
                edirTOA( 18 , 5 ) =  4.36198919156
                edirTOA( 18 , 1 ) =  10.7215408425
                edirTOA( 5 , 0 ) =  29.5130809504
                edirTOA( 32 , 12 ) =  0.0
                edirTOA( 32 , 9 ) =  0.00976817997502
                edirTOA( 32 , 1 ) =  0.142673449552
                edirTOA( 32 , 5 ) =  0.376941944997
                edirTOA( 32 , 0 ) =  0.0623608206851
                edirTOA( 32 , 4 ) =  0.336954474089
                edirTOA( 32 , 8 ) =  0.227014829619
                edirTOA( 32 , 13 ) =  0.0
                edirTOA( 32 , 2 ) =  0.217265794354
                edirTOA( 32 , 6 ) =  0.400514954119
                edirTOA( 32 , 11 ) =  0.0
                edirTOA( 32 , 10 ) =  1.48209481959e-12
                edirTOA( 32 , 14 ) =  0.0
                edirTOA( 32 , 3 ) =  0.282933827056
                edirTOA( 32 , 7 ) =  0.401268900631
                edirTOA( 28 , 0 ) =  0.632889918429
                edirTOA( 28 , 4 ) =  1.86619596973
                edirTOA( 28 , 1 ) =  1.36693524039
                edirTOA( 28 , 5 ) =  1.36704833196
                edirTOA( 28 , 3 ) =  2.04287751395
                edirTOA( 28 , 2 ) =  1.86602376619
                edirTOA( 28 , 6 ) =  0.632684847301
                edirTOA( 11 , 0 ) =  29.9087198533
                edirTOA( 16 , 2 ) =  6.70081928218
                edirTOA( 16 , 3 ) =  6.69464709261
                edirTOA( 16 , 1 ) =  5.16635900799
                edirTOA( 16 , 5 ) =  2.38105176468
                edirTOA( 16 , 0 ) =  2.45536917953
                edirTOA( 16 , 4 ) =  5.1656324302
                edirTOA( 15 , 0 ) =  25.8876083076
                edirTOA( 14 , 2 ) =  18.3408133837
                edirTOA( 14 , 3 ) =  15.4234125035
                edirTOA( 14 , 1 ) =  15.4167800247
                edirTOA( 14 , 4 ) =  7.63049410672
                edirTOA( 14 , 0 ) =  7.64065745932
                edirTOA( 2 , 0 ) =  3.63522357095e-15
                edirTOA( 20 , 3 ) =  10.0879387185
                edirTOA( 20 , 2 ) =  10.087460167
                edirTOA( 20 , 4 ) =  7.77298727896
                edirTOA( 20 , 0 ) =  3.69400327816
                edirTOA( 20 , 5 ) =  3.69572175159
                edirTOA( 20 , 1 ) =  7.7855686521
                edirTOA( 3 , 0 ) =  0.0535499520864
                edirTOA( 17 , 2 ) =  11.9025032599
                edirTOA( 17 , 3 ) =  11.9057646701
                edirTOA( 17 , 1 ) =  9.17423536469
                edirTOA( 17 , 5 ) =  4.35807660191
                edirTOA( 17 , 0 ) =  4.35494556682
                edirTOA( 17 , 4 ) =  9.17534503079
                edirTOA( 29 , 1 ) =  2.91622168941
                edirTOA( 29 , 5 ) =  4.80709653617
                edirTOA( 29 , 0 ) =  1.31208543368
                edirTOA( 29 , 4 ) =  5.30954453501
                edirTOA( 29 , 8 ) =  3.24238783861e-14
                edirTOA( 29 , 2 ) =  4.20668094838
                edirTOA( 29 , 6 ) =  2.83409124753
                edirTOA( 29 , 3 ) =  5.039890471
                edirTOA( 29 , 7 ) =  0.209181052772
                edirTOA( 4 , 0 ) =  8.28119814586
                edirTOA( 27 , 3 ) =  4.60682077094
                edirTOA( 27 , 2 ) =  4.62809736294
                edirTOA( 27 , 0 ) =  1.69623541818
                edirTOA( 27 , 4 ) =  3.45201982882
                edirTOA( 27 , 1 ) =  3.57159870746
                edirTOA( 27 , 5 ) =  1.09960248101
                edirTOA( 19 , 3 ) =  13.4925604029
                edirTOA( 19 , 2 ) =  13.4965114188
                edirTOA( 19 , 0 ) =  4.94240255958
                edirTOA( 19 , 4 ) =  10.4013708205
                edirTOA( 19 , 1 ) =  10.4078104597
                edirTOA( 19 , 5 ) =  4.93439920407
                edirTOA( 30 , 6 ) =  1.28570133243
                edirTOA( 30 , 2 ) =  1.82469101324
                edirTOA( 30 , 7 ) =  0.543146049847
                edirTOA( 30 , 3 ) =  2.10923731522
                edirTOA( 30 , 5 ) =  1.82208568327
                edirTOA( 30 , 1 ) =  1.29361512888
                edirTOA( 30 , 4 ) =  2.1086300771
                edirTOA( 30 , 0 ) =  0.588864687949
                edirTOA( 10 , 0 ) =  16.828583559
                edirTOA( 8 , 0 ) =  122.58323652
                edirTOA( 25 , 0 ) =  2.22887170531
                edirTOA( 25 , 4 ) =  4.68787944302
                edirTOA( 25 , 1 ) =  4.69359696657
                edirTOA( 25 , 5 ) =  2.20175327522
                edirTOA( 25 , 3 ) =  6.0867125113
                edirTOA( 25 , 2 ) =  6.08642294258
                edirTOA( 1 , 0 ) =  2.40868087524e-43
                edirTOA( 26 , 6 ) =  8.15166908597
                edirTOA( 26 , 2 ) =  5.78476957323
                edirTOA( 26 , 7 ) =  7.20884077617
                edirTOA( 26 , 3 ) =  7.24055108183
                edirTOA( 26 , 9 ) =  3.64320590223
                edirTOA( 26 , 5 ) =  8.47352225838
                edirTOA( 26 , 1 ) =  3.89994937568
                edirTOA( 26 , 10 ) =  0.676894983402
                edirTOA( 26 , 4 ) =  8.16068351309
                edirTOA( 26 , 0 ) =  1.72872813333
                edirTOA( 26 , 8 ) =  5.70448645738
endif
                !}}}

        !{{{ TOA=120e3
        if(z.gt.dble(10e3)) then
                ednTOA = 0
                edirTOA( 20 , 2 ) =  10.1306409207
                edirTOA( 20 , 3 ) =  10.1306410263
                edirTOA( 20 , 5 ) =  3.70928662652
                edirTOA( 20 , 1 ) =  7.810722518
                edirTOA( 20 , 4 ) =  7.81072252341
                edirTOA( 20 , 0 ) =  3.70928661651
                edirTOA( 29 , 0 ) =  1.3120856003
                edirTOA( 29 , 4 ) =  5.33135111713
                edirTOA( 29 , 8 ) =  1.31208559909
                edirTOA( 29 , 1 ) =  2.91636583991
                edirTOA( 29 , 5 ) =  5.04249994409
                edirTOA( 29 , 3 ) =  5.0424999118
                edirTOA( 29 , 7 ) =  2.91636584395
                edirTOA( 29 , 2 ) =  4.20727304341
                edirTOA( 29 , 6 ) =  4.20727302121
                edirTOA( 26 , 7 ) =  7.24261348953
                edirTOA( 26 , 3 ) =  7.24261345459
                edirTOA( 26 , 6 ) =  8.16227542045
                edirTOA( 26 , 2 ) =  5.78586648089
                edirTOA( 26 , 8 ) =  5.78586648749
                edirTOA( 26 , 4 ) =  8.16227542045
                edirTOA( 26 , 0 ) =  1.72897381937
                edirTOA( 26 , 10 ) =  1.72897380617
                edirTOA( 26 , 5 ) =  8.47660282089
                edirTOA( 26 , 1 ) =  3.90031900743
                edirTOA( 26 , 9 ) =  3.90031899928
                edirTOA( 3 , 0 ) =  11.6004005184
                edirTOA( 16 , 2 ) =  6.82911036421
                edirTOA( 16 , 3 ) =  6.82911033503
                edirTOA( 16 , 1 ) =  5.26524300744
                edirTOA( 16 , 5 ) =  2.50044669931
                edirTOA( 16 , 0 ) =  2.50044669803
                edirTOA( 16 , 4 ) =  5.26524294724
                edirTOA( 8 , 0 ) =  128.678000458
                edirTOA( 25 , 0 ) =  2.229505498
                edirTOA( 25 , 4 ) =  4.69471642098
                edirTOA( 25 , 1 ) =  4.69471641122
                edirTOA( 25 , 5 ) =  2.22950549898
                edirTOA( 25 , 3 ) =  6.08912766642
                edirTOA( 25 , 2 ) =  6.08912762413
                edirTOA( 4 , 0 ) =  15.4937007408
                edirTOA( 10 , 0 ) =  17.760900938
                edirTOA( 15 , 0 ) =  26.5117015907
                edirTOA( 31 , 1 ) =  1.2237047393
                edirTOA( 31 , 0 ) =  0.652725270556
                edirTOA( 31 , 2 ) =  1.22370473413
                edirTOA( 31 , 3 ) =  0.652725266569
                edirTOA( 32 , 11 ) =  0.283066083313
                edirTOA( 32 , 7 ) =  0.410852978512
                edirTOA( 32 , 3 ) =  0.283066083389
                edirTOA( 32 , 6 ) =  0.402442865031
                edirTOA( 32 , 2 ) =  0.217331758483
                edirTOA( 32 , 10 ) =  0.337213902859
                edirTOA( 32 , 14 ) =  0.0623712650129
                edirTOA( 32 , 8 ) =  0.402442865665
                edirTOA( 32 , 4 ) =  0.337213901591
                edirTOA( 32 , 0 ) =  0.0623712647848
                edirTOA( 32 , 12 ) =  0.217331758357
                edirTOA( 32 , 13 ) =  0.142710788611
                edirTOA( 32 , 5 ) =  0.377556848334
                edirTOA( 32 , 1 ) =  0.142710788611
                edirTOA( 32 , 9 ) =  0.37755684765
                edirTOA( 1 , 0 ) =  4.03338018352
                edirTOA( 27 , 2 ) =  4.63337718642
                edirTOA( 27 , 3 ) =  4.63337719261
                edirTOA( 27 , 5 ) =  1.69648930397
                edirTOA( 27 , 1 ) =  3.57233304302
                edirTOA( 27 , 4 ) =  3.57233306283
                edirTOA( 27 , 0 ) =  1.69648930286
                edirTOA( 17 , 2 ) =  12.002039519
                edirTOA( 17 , 3 ) =  12.0020395799
                edirTOA( 17 , 1 ) =  9.25357051742
                edirTOA( 17 , 5 ) =  4.3944904533
                edirTOA( 17 , 0 ) =  4.3944904424
                edirTOA( 17 , 4 ) =  9.25357057193
                edirTOA( 2 , 0 ) =  2.2788600856
                edirTOA( 14 , 2 ) =  19.0127498116
                edirTOA( 14 , 3 ) =  15.9961765614
                edirTOA( 14 , 1 ) =  15.9961765322
                edirTOA( 14 , 0 ) =  7.91829778131
                edirTOA( 14 , 4 ) =  7.91829770611
                edirTOA( 21 , 3 ) =  15.5192217444
                edirTOA( 21 , 6 ) =  4.80789994728
                edirTOA( 21 , 2 ) =  14.1777128397
                edirTOA( 21 , 4 ) =  14.1777129372
                edirTOA( 21 , 0 ) =  4.80789995749
                edirTOA( 21 , 5 ) =  10.385727358
                edirTOA( 21 , 1 ) =  10.3857272883
                edirTOA( 7 , 0 ) =  78.7000009153
                edirTOA( 11 , 0 ) =  31.6404016295
                edirTOA( 30 , 6 ) =  1.29363495026
                edirTOA( 30 , 2 ) =  1.82489432002
                edirTOA( 30 , 7 ) =  0.588866641292
                edirTOA( 30 , 3 ) =  2.10980412428
                edirTOA( 30 , 5 ) =  1.82489432002
                edirTOA( 30 , 1 ) =  1.29363496116
                edirTOA( 30 , 4 ) =  2.10980411047
                edirTOA( 30 , 0 ) =  0.588866640637
                edirTOA( 22 , 0 ) =  4.41704515368
                edirTOA( 22 , 4 ) =  9.30106449142
                edirTOA( 22 , 1 ) =  9.30106451076
                edirTOA( 22 , 5 ) =  4.41704515046
                edirTOA( 22 , 3 ) =  12.0636399919
                edirTOA( 22 , 2 ) =  12.0636399757
                edirTOA( 19 , 2 ) =  13.5620647094
                edirTOA( 19 , 3 ) =  13.5620647022
                edirTOA( 19 , 5 ) =  4.96568631308
                edirTOA( 19 , 1 ) =  10.456349634
                edirTOA( 19 , 4 ) =  10.4563497753
                edirTOA( 19 , 0 ) =  4.96568631344
                edirTOA( 13 , 0 ) =  34.3619018641
                edirTOA( 6 , 0 ) =  54.1390028186
                edirTOA( 9 , 0 ) =  41.7882027841
                edirTOA( 23 , 1 ) =  12.0799580059
                edirTOA( 23 , 5 ) =  12.0799581733
                edirTOA( 23 , 0 ) =  5.5922159709
                edirTOA( 23 , 4 ) =  16.4905329605
                edirTOA( 23 , 2 ) =  16.4905329551
                edirTOA( 23 , 6 ) =  5.59221596766
                edirTOA( 23 , 3 ) =  18.0508831382
                edirTOA( 12 , 1 ) =  12.5689153151
                edirTOA( 12 , 5 ) =  5.96893683509
                edirTOA( 12 , 0 ) =  5.9689368512
                edirTOA( 12 , 4 ) =  12.5689153195
                edirTOA( 12 , 2 ) =  16.3020985166
                edirTOA( 12 , 3 ) =  16.3020984817
                edirTOA( 24 , 1 ) =  13.7260244735
                edirTOA( 24 , 5 ) =  19.3629152082
                edirTOA( 24 , 0 ) =  6.24812887769
                edirTOA( 24 , 4 ) =  22.3859309799
                edirTOA( 24 , 2 ) =  19.3629152391
                edirTOA( 24 , 6 ) =  13.7260246587
                edirTOA( 24 , 3 ) =  22.3859308719
                edirTOA( 24 , 7 ) =  6.24812890932
                edirTOA( 5 , 0 ) =  35.2634033031
                edirTOA( 28 , 6 ) =  0.632919926553
                edirTOA( 28 , 2 ) =  1.86637764597
                edirTOA( 28 , 3 ) =  2.04297611205
                edirTOA( 28 , 5 ) =  1.36719435832
                edirTOA( 28 , 1 ) =  1.3671943736
                edirTOA( 28 , 4 ) =  1.86637764902
                edirTOA( 28 , 0 ) =  0.632919925147
                edirTOA( 18 , 0 ) =  5.12121442678
                edirTOA( 18 , 4 ) =  10.7838485406
                edirTOA( 18 , 1 ) =  10.7838484546
                edirTOA( 18 , 5 ) =  5.12121443351
                edirTOA( 18 , 3 ) =  13.9868361866
                edirTOA( 18 , 2 ) =  13.9868362501
        endif
        !}}}
        end subroutine

        function get_ednTOA(k,q,z)
                real(ireals),intent(in) :: z
                real(ireals) :: get_ednTOA
                integer(iintegers),intent(in) :: k,q
                if( .not.allocated(ednTOA) ) call setup(z)
                get_ednTOA = ednTOA(k,q)
                if(get_ednTOA.eq.-1) then
                        print *,'kato edir TOA was called for kato band',k,q,' this seems not to exits,', &
                                ' please check for the correct band. Calling exit...)'
                        call exit()
                endif
        end function
        function get_edirTOA(k,q,z)
                real(ireals),intent(in) :: z
                real(ireals) :: get_edirTOA
                integer(iintegers),intent(in) :: k,q
                if( .not.allocated(edirTOA) ) call setup(z)
                get_edirTOA = edirTOA(k,q)
                if(get_edirTOA.eq.-1) then
                        print *,'kato edir TOA was called for kato band',k,q,' this seems not to exits,', &
                                 'please check for the correct band. Calling exit...)'
                        call exit()
                endif
        end function

endmodule
