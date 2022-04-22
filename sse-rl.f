***
      subroutine sserl(mass,ospin,tfin,kw,mass0,N,time,mv,rv
     &     ,dmdtv,menvv,renvv,luminv,kwv,jj,tco,dms,Rmax,fb,z,epc,tmax,
     &      mco0,dtp)
      
c-------------------------------------------------------------c
c
c     Evolves a single star.
c     Mass loss is an option.
c     The timestep is not constant but determined by certain criteria.
c
c     Written by Jarrod Hurley 26/08/97 at the Institute of
c     Astronomy, Cambridge.
c
c-------------------------------------------------------------c
c
c     STELLAR TYPES - KW
c
c        0 - deeply or fully convective low mass MS star
c        1 - Main Sequence star
c        2 - Hertzsprung Gap
c        3 - First Giant Branch
c        4 - Core Helium Burning
c        5 - First Asymptotic Giant Branch
c        6 - Second Asymptotic Giant Branch
c        7 - Main Sequence Naked Helium star
c        8 - Hertzsprung Gap Naked Helium star
c        9 - Giant Branch Naked Helium star
c       10 - Helium White Dwarf
c       11 - Carbon/Oxygen White Dwarf
c       12 - Oxygen/Neon White Dwarf
c       13 - Neutron Star
c       14 - Black Hole
c       15 - Massless Supernova
c
c-------------------------------------------------------------c 
      implicit none
*
      
      INCLUDE 'const_bse.h'
      
*
      integer kw,j,k,N,j1,j2,kick,jj
*
      real*8 mass,mt,z,zpars(20),ut,tco,dms,Rmax
      real*8 epoch,tms,tphys,tphysf,dtp,mcmax,mco,epc,tmax
      real*8 r,lum,ospin,mv(N),rv(N),dmdtv(N),time(N),mass0,kwv(N)
      real*8 menvv(N),renvv(N),luminv(N)
      real*8 mc,rc,menv,renv,dmdt,spin,tfin,fallback,fb
      real*8 mco0
      character*50 text1,text2,text3
      character*30 label(16)
      common /fall/fallback
      COMMON/mco/mcmax
      data label /' Low Mass MS Star ',' Main sequence Star ',
     &            ' Hertzsprung Gap ',' Giant Branch ',
     &            ' Core Helium Burning ',
     &            ' First AGB ',' Second AGB ',
     &            ' Naked Helium MS ',' Naked Helium HG ',
     &            ' Naked Helium GB ',' Helium WD ',
     &            ' Carbon/Oxygen WD ',' Oxygen/Neon WD ',
     &            ' Neutron Star ',' Black Hole ',
     &            ' Massless Supernova '/
*
************************************************************************
* Input:
*
* mass is in solar units.
* z is metallicity in the range 0.0001 -> 0.03 where 0.02 is Population I.
* tphysf is the maximum evolution time in Myr.
*
* neta is the Reimers mass-loss coefficent (neta*4x10^-13; 0.5 normally).
* bwind is the binary enhanced mass loss parameter (inactive for single).
* hewind is a helium star mass loss factor (1.0 normally). 
* sigma is the dispersion in the Maxwellian for the SN kick speed (190 km/s). 
*
* ifflag > 0 uses WD IFMR of HPE, 1995, MNRAS, 272, 800 (0). 
* wdflag > 0 uses modified-Mestel cooling for WDs (0). 
* bhflag > 0 allows velocity kick at BH formation (0). 
* nsflag > 0 takes NS/BH mass from Belczynski et al. 2002, ApJ, 572, 407 (1). 
* mxns is the maximum NS mass (1.8, nsflag=0; 3.0, nsflag=1). 
* idum is the random number seed used in the kick routine. 
*
* Next come the parameters that determine the timesteps chosen in each
* evolution phase:
*                 pts1 - MS                  (0.05)
*                 pts2 - GB, CHeB, AGB, HeGB (0.01)
*                 pts3 - HG, HeMS            (0.02)
* as decimal fractions of the time taken in that phase.
*
* If you enter a negative mass then parameters for an evolved star are
* required in the order of:
* initial mass, current mass, type, current time & epoch,
* otherwise the star will start on the ZAMS.
*
      ut=58./365.               !unit of time in LKspin.f
c      mass=mass0
      tphysf=tmax
      neta=0.5
      bwind=0.0
      hewind=0.5
      ifflag=0
      wdflag=1
      mxns=3.d0
      pts1=0.01
      pts2=0.01
      pts3=0.02

      tphys=tfin
      epoch=epc
      mt=mass
      mass=mass0
     
*
************************************************************************
*
* Set parameters which depend on the metallicity 
*
      CALL zcnsts(z,zpars)

      if(idum.gt.0) idum = -idum
*
* Obtain parameters of evolved star.
*
c         READ(22,*)mass,mt,kw,tphys,epoch
c      endif
*
* Set the initial spin of the star. If ospin is less than or equal to 
* zero at time zero then evolv1 will set an appropriate ZAMS spin. If 
* ospin is greater than zero then it will start with that spin regardless
* of the time. If you want to start at time zero with negligible spin 
* then I suggest using a negligible value (but greater than 0.001).
*
c     ospin = 0.d0
*
* Set the data-save parameter. If dtp  is zero then the parameters of the 
* star will be stored in the scm array at each timestep otherwise they 
* will be stored at intervals of dtp. Setting dtp equal to tphysf will 
* store data only at the start and end while a value of dtp greater than 
* tphysf will mean that no data is stored.
*

      tco=1.d10
*

      CALL evolv1(kw,mass,mt,r,lum,mc,rc,menv,renv,ospin,
     &     epoch,tms,tphys,tphysf,dtp,z,zpars)

*
************************************************************************
*     Output:
*

      Rmax=-8.
      j2=0
      if(scm(1,1).lt.0.0) goto 50
*
*     The scm array stores the stellar parameters at the specified output 
*     times. The parameters are (in order of storage):
*    
*     Time, stellar type, initial mass, current mass, log10(L), log10(r),
*     log10(Teff), core mass, epoch and spin.
*
c      OPEN(23,file='evolveRL.dat',status='unknown')
c      text1 = ' Tev(Myr)    type      Mo        Mt      log10(L) '
c      text2 = ' log10(R) log10(Teff)  Mc        Menv     ' 
c      text3 = ' epoch      spin' 
c      WRITE(23,'(a,a,a)')text1,text2,text3
*
************************************************************************
*
* Interpolation
*
      j = 1
      jj = 1
      time(jj)=scm(j,1)*1.e6/ut
      mv(jj)=scm(j,4)
      rv(jj)=scm(j,6)
      dmdtv(jj)=-1.e-12
      dmdtv(jj)=log10(abs(dmdtv(jj)))
      kwv(jj)=scm(j,2)
      menvv(jj)=scm(j,10)
      renvv(jj)=scm(j,11)
      luminv(jj)=scm(j,5)

 30   j = j + 1
      if(scm(j,1).ge.0.0) then
        if((scm(j,1)*1.e6/ut).eq.time(jj)) goto 30
        jj = jj + 1
        time(jj)=scm(j,1)*1.e6/ut
        mv(jj)=scm(j,4)
        rv(jj)=scm(j,6)
        kwv(jj)=scm(j,2)
        menvv(jj)=scm(j,10)
        renvv(jj)=scm(j,11)
        luminv(jj)=scm(j,5)
        dmdtv(jj)=(mv(jj)-mv(jj-1))/(time(jj)-time(jj-1)) !converted to LKspin units
        if((mv(jj)-mv(jj-1)).eq.0.
     &     .or.scm(j,2).gt.9)dmdtv(jj)=-1.e-12
        dmdtv(jj)=log10(abs(dmdtv(jj)))

        if(rv(jj).gt.Rmax)Rmax=rv(jj)
        if(scm(j,2).gt.12.and.j2.eq.0)then
            tco=time(jj)
            mco0=mv(jj)
            dms=mv(jj-1)-mv(jj)
            j2=1
        end if
        goto 30
      elseif(kw.eq.15.and.scm(j,1).lt.0.0)then
        tco=tphysf*1.e6/ut
        goto 32
      else
        goto 32
      endif
 32   continue

*     
* The spp array acts as a log, storing the time and mass at each change
* of evolution stage.
*
      j1 = 0
 50   j1 = j1 + 1
      if(spp(j1,1).lt.0.0) goto 60
      kw = INT(spp(j1,2))
      WRITE(*,100)label(kw+1),spp(j1,1),spp(j1,3)
      goto 50
 60   continue
 100  format(a30,' Time ',f10.1,' Mass ',f7.3)
c      WRITE(*,*)
*
************************************************************************
*
      Rmax=0.00465d0*10.**Rmax
      print*,'maximum stellar radius(AU) ',Rmax
      print*,'CO core mass and fb ',mcmax,fallback
      mco=mcmax
      fb=fallback
      RETURN 
      END SUBROUTINE
***
