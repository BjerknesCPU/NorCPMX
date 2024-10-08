      subroutine micom_step
c
c --- ------------------------------------------------------------------
c --- integrate a model time step
c --- ------------------------------------------------------------------
c
      use mod_xc
      use mod_dia
#ifdef NUDGE_TS
      use mod_nudge_ts
#endif
c
      implicit none
c
#include "common_blocks.h"
#include "common_clndr.h"
#include "common_forc.h"
#ifdef TKE
#  include "common_tke.h"
#endif
#ifdef TRC
#  include "param_trc.h"
#  include "common_trc.h"
#endif
#include "param_bud.h"
#include "common_bud.h"
#include "timing.h"
c
      real q
      integer i,j,k,l,m,n,mm,nn,k1m,k1n
c
      real step_time,
     .     auxil_time ,
     .     getflx_time,
     .     seaice_time,
     .     tmsmt1_time,
     .     advdif_time,
     .     sfcstr_time,
     .     momtum_time,
     .     pgforc_time,
     .     barotp_time,
     .     pbtcor_time,
     .     convec_time,
     .     diapfl_time,
     .     thermf_time,
     .     mxlayr_time,
     .     tmsmt2_time,
     .     diaacc_time,
     .     io_time
c
      real gettime
      external gettime
c
c --- letter 'm' refers to mid-time level (example: dp(i,j,km) )
c --- letter 'n' refers to old and new time level
c
      m=mod(nstep  ,2)+1
      n=mod(nstep+1,2)+1
      mm=(m-1)*kk
      nn=(n-1)*kk
      k1m=1+mm
      k1n=1+nn
c
      nstep=nstep+1
      time=nstep*baclin/86400.
c
#ifdef TRC
c --- advance tracers only every second time step
      ntrc=ntr*mod(nstep+1,2)
#  ifdef ATRC
      natrc=natr*mod(nstep+1,2)
#  endif
#endif
c
      if (cnsvdi) call stdbud(1,n,nn)
c
c --- Update calender
      call updcln(nstep)
c
c --- ------------------------------------------------------------------
c --- Update some flux halos the first time step of a day to reproduce
c --- results after restart with arctic
c --- ------------------------------------------------------------------
c
      if (nreg.eq.2.and.mod(nstep,nstep_in_day).eq.1) then
        if (mnproc.eq.1) write (lp,*) 'micom_step: update flux halos'
        call xctilr(uflx(1-nbdy,1-nbdy,k1n), 1,kk, 1,1, halo_uv)
        call xctilr(utflx(1-nbdy,1-nbdy,k1n), 1,kk, 1,1, halo_uv)
        call xctilr(usflx(1-nbdy,1-nbdy,k1n), 1,kk, 1,1, halo_uv)
        call xctilr(vflx(1-nbdy,1-nbdy,k1n), 1,kk, 1,1, halo_vv)
        call xctilr(vtflx(1-nbdy,1-nbdy,k1n), 1,kk, 1,1, halo_vv)
        call xctilr(vsflx(1-nbdy,1-nbdy,k1n), 1,kk, 1,1, halo_vv)
      endif
c
c --- ------------------------------------------------------------------
c --- Set parameters for time interpolation of climatological fields
c --- ------------------------------------------------------------------
c
      x=(nday_of_year-1+mod(nstep,nstep_in_day)/real(nstep_in_day))*12.
     .  /real(nday_in_year)
      l3=int(x)+1
      x=x-real(l3-1)
      l1=mod(l3+ 9,12)+1
      l2=mod(l3+10,12)+1
      l4=mod(l3   ,12)+1
      l5=mod(l3+ 1,12)+1
c
      auxil_time=gettime()
c
#ifdef NEST
c --- ------------------------------------------------------------------
c --- Get boundary conditions from outer coarse model
c --- ------------------------------------------------------------------
c
      call rdotr
#endif
c
c --- ------------------------------------------------------------------
c --- Get surface fluxes
c --- ------------------------------------------------------------------
c
#if   defined(CLIM)
      call getflux_clim
#elif defined(SYN)
      call getflux_syn
#elif defined(CCSMCOUPLED)
      call getflux_ccsm
#endif
c
      getflx_time=gettime()
c
#ifdef ICEDYN
cdiag write (lp,*) 'icedyn...'
      call icedyn(m,n,mm,nn,k1m,k1n)
#endif
      seaice_time=gettime()
c
cdiag write (lp,*) 'tmsmt1...'
      call tmsmt1(m,n,mm,nn,k1m,k1n)
      tmsmt1_time=gettime()
c
cdiag write (lp,*) 'advdif...'
      call difest(m,n,mm,nn,k1m,k1n)
      call intdif(m,n,mm,nn,k1m,k1n)
      call advect(m,n,mm,nn,k1m,k1n)
      call diffus(m,n,mm,nn,k1m,k1n)
      advdif_time=gettime()
c
      if (cnsvdi) call stdbud(2,n,nn)
      auxil_time=auxil_time+gettime()
c
cdiag write (lp,*) 'sfcstr...'
#ifdef CCSMCOUPLED
      call sfcstr_ccsm(m,n,mm,nn,k1m,k1n)
#else
      call sfcstr(m,n,mm,nn,k1m,k1n)
#endif
      sfcstr_time=gettime()
c
cdiag write (lp,*) 'pgforc...'
      call pgforc(m,n,mm,nn,k1m,k1n)
      pgforc_time=gettime()
c
cdiag write (lp,*) 'momtum...'
      call momtum(m,n,mm,nn,k1m,k1n)
      momtum_time=gettime()
c
#ifdef NEST
cdiag write (lp,*) 'bclnst...'
      call bclnst(m,n,mm,nn,k1m,k1n)
c     bclnst_time=gettime()
#endif
c
cdiag write (lp,*) 'convec...'
      call convec(m,n,mm,nn,k1m,k1n)
      convec_time=gettime()
c
      if (cnsvdi) call stdbud(3,n,nn)
      auxil_time=auxil_time+gettime()
c
cdiag write (lp,*) 'diapfl...'
      call diapfl(m,n,mm,nn,k1m,k1n)
      diapfl_time=gettime()
c
      if (cnsvdi) call stdbud(4,n,nn)
      auxil_time=auxil_time+gettime()
c
cdiag write (lp,*) 'thermf...'
#ifdef CCSMCOUPLED
      call thermf_ccsm(m,n,mm,nn,k1m,k1n)
#else
      call thermf(m,n,mm,nn,k1m,k1n)
#endif
      thermf_time=gettime()
c
cdiag write (lp,*) 'mxlayr...'
      call mxlayr(m,n,mm,nn,k1m,k1n)
      mxlayr_time=gettime()
c
#ifdef TRC
c --- update tracer due to non-passive processes
      if (mod(nstep+1,2).eq.1) call updtrc(m,n,mm,nn,k1m,k1n)
#endif
c
      if (cnsvdi) call stdbud(5,n,nn)
      auxil_time=auxil_time+gettime()
c
cdiag write (lp,*) 'barotp...'
      call barotp(m,n,mm,nn,k1m,k1n)
      barotp_time=gettime()
c
cdiag write (lp,*) 'pbtcor...'
      call pbtcor(m,n,mm,nn,k1m,k1n)
      pbtcor_time=gettime()
c
      if (cnsvdi) call stdbud(6,m,mm)
      auxil_time=auxil_time+gettime()
c
cdiag write (lp,*) 'tmsmt2...'
      call tmsmt2(m,n,mm,nn,k1m,k1n)
      tmsmt2_time=gettime()
c
      if (cnsvdi) call stdbud(7,m,mm)
c
      if (sprfac) call fwbbal(m,n,mm,nn,k1m,k1n)
c
      if (cnsvdi) then
        if (mnproc.eq.1.and.nstep.gt.nstep1+1) then
          open (unit=nfu,file='salbud',position='append')
          write (nfu,'(i8,6e12.4)') nstep-1,
     .      (sdp(2,m)-sdp(1,m))/mass0,
     .      (sdp(3,m)-sdp(2,m))/mass0,
     .      (sdp(4,m)-sdp(3,m))/mass0,
     .      (sdp(5,m)-sdp(4,m)+sf*g)/mass0,
     .      (sdp(6,m)-sdp(5,m))/mass0,
     .      (sdp(7,m)-sdp(6,m))/mass0
          close (nfu)
          open (unit=nfu,file='tembud',position='append')
          write (nfu,'(i8,6e12.4)') nstep-1,
     .      (tdp(2,m)-tdp(1,m))/mass0,
     .      (tdp(3,m)-tdp(2,m))/mass0,
     .      (tdp(4,m)-tdp(3,m))/mass0,
     .      (tdp(5,m)-tdp(4,m)+tf*g/spcifh)/mass0,
     .      (tdp(6,m)-tdp(5,m))/mass0,
     .      (tdp(7,m)-tdp(6,m))/mass0
          close (nfu)
#ifdef TKE
          open (unit=nfu,file='tkebud',position='append')
          write (nfu,'(i8,6e12.4)') nstep-1,
     .      (tkedp(2,m)-tkedp(1,m))/mass0,
     .      (tkedp(3,m)-tkedp(2,m))/mass0,
     .      (tkedp(4,m)-tkedp(3,m))/mass0,
     .      (tkedp(5,m)-tkedp(4,m))/mass0,
     .      (tkedp(6,m)-tkedp(5,m))/mass0,
     .      (tkedp(7,m)-tkedp(6,m))/mass0
          close (nfu)
#  ifdef GLS
          open (unit=nfu,file='glsbud',position='append')
          write (nfu,'(i8,6e12.4)') nstep-1,
     .      (glsdp(2,m)-glsdp(1,m))/mass0,
     .      (glsdp(3,m)-glsdp(2,m))/mass0,
     .      (glsdp(4,m)-glsdp(3,m))/mass0,
     .      (glsdp(5,m)-glsdp(4,m))/mass0,
     .      (glsdp(6,m)-glsdp(5,m))/mass0,
     .      (glsdp(7,m)-glsdp(6,m))/mass0
          close (nfu)
#  endif
#endif
#ifdef TRC
          if (m.eq.1) then
            open (unit=nfu,file='trcbud',position='append')
            write (nfu,'(i8,6e12.4)') nstep,
     .        (trdp(2)-trdp(1))/mass0,
     .        (trdp(3)-trdp(2))/mass0,
     .        (trdp(4)-trdp(3))/mass0,
     .        (trdp(5)-trdp(4)+trf*g)/mass0,
     .        (trdp(6)-trdp(5))/mass0,
     .        (trdp(7)-trdp(6))/mass0
            close (nfu)
            open (unit=nfu,file='trcbudtot',position='append')
            write (nfu,'(i8,7e18.10)') nstep,
     .        trdp(1)/mass0,trdp(2)/mass0,trdp(3)/mass0,
     .        trdp(4)/mass0,trdp(5)/mass0,trdp(6)/mass0,trdp(7)/mass0
            close (nfu)
          endif
#endif
        endif
c$OMP PARALLEL DO
        do j=1,jj
          do l=1,isp(j)
          do i=max(1,ifp(j,l)),min(ii,ilp(j,l))
            util1(i,j)=(salflx(i,j)+salrlx(i,j))*scp2(i,j)*delt1
            util2(i,j)=(surflx(i,j)+surrlx(i,j))*scp2(i,j)*delt1
#ifdef TRC
            util3(i,j)=trflx(1,i,j)*scp2(i,j)*delt1
#endif
          enddo
          enddo
        enddo
c$OMP END PARALLEL DO
        call xcsum(sf,util1,ips)
        call xcsum(tf,util2,ips)
#ifdef TRC
        call xcsum(trf,util3,ips)
#endif
      endif
c
      auxil_time=auxil_time+gettime()
c
c --- ------------------------------------------------------------------
c --- - nudging 
c --- ------------------------------------------------------------------
#ifdef NUDGE_TS
      call nudge_ts(m,n,mm,nn,k1m,k1n)
#endif
c
c
c ----------------------------------------------------------------------
c
c --- output and diagnostic calculations
c
c ----------------------------------------------------------------------
c
      call chkvar(m,n,mm,nn,k1m,k1n)
c
      call diaacc(m,n,mm,nn,k1m,k1n)
      diaacc_time=gettime()
c
      if (mod(nstep,nstep_in_day).eq.0.and.nday_of_year.eq.1) then
c
c --- ------------------------------------------------------------------
c --- - output diagnosed heat and salt flux
c --- ------------------------------------------------------------------
c
        call wdiflx
c
      endif
c
c
c --- ------------------------------------------------------------------
c --- - output of MICOM diagnostics
c --- ------------------------------------------------------------------
c
      do i=1,nphy 
        if (((diagann_phy(i).and.nday_of_year.eq.1.or.diagmon_phy(i)
     .    .and.nday.eq.1).and.mod(nstep,nstep_in_day).eq.0).or..not.
     .    (diagann_phy(i).or.diagmon_phy(i)).and.
     .    mod(nstep+.5,diagfq_phy(i)).lt.1.) 
     .    call diaout(i,m,n,mm,nn,k1m,k1n)
      enddo
c
c --- update total time spent by various tasks
      auxil_total_time=auxil_total_time+auxil_time
      getflx_total_time=getflx_total_time+getflx_time
      seaice_total_time=seaice_total_time+seaice_time
      tmsmt1_total_time=tmsmt1_total_time+tmsmt1_time
      advdif_total_time=advdif_total_time+advdif_time
      sfcstr_total_time=sfcstr_total_time+sfcstr_time
      momtum_total_time=momtum_total_time+momtum_time
      pgforc_total_time=pgforc_total_time+pgforc_time
      barotp_total_time=barotp_total_time+barotp_time
      pbtcor_total_time=pbtcor_total_time+pbtcor_time
      convec_total_time=convec_total_time+convec_time
      diapfl_total_time=diapfl_total_time+diapfl_time
      thermf_total_time=thermf_total_time+thermf_time
      mxlayr_total_time=mxlayr_total_time+mxlayr_time
      tmsmt2_total_time=tmsmt2_total_time+tmsmt2_time
      diaacc_total_time=diaacc_total_time+diaacc_time
c
      if (((rstann.and.nday_of_year.eq.1.or.rstmon.and.nday
     .  .eq.1).and.mod(nstep,nstep_in_day).eq.0).or..not.(rstann
     .  .or.rstmon).and.mod(nstep+.5,rstfrq).lt.1.) then
c
#ifndef CCSMCOUPLED
c --- ------------------------------------------------------------------
c --- - output restart files
c --- ------------------------------------------------------------------
c
        call restart_wt
#endif
c
        io_time=gettime()
c
c --- ------------------------------------------------------------------
c --- - write timing diagnostics to standard out
c --- ------------------------------------------------------------------
c
        io_total_time=io_total_time+io_time
        step_time=auxil_time +getflx_time+seaice_time+tmsmt1_time
     .           +advdif_time+sfcstr_time+momtum_time+pgforc_time
     .           +barotp_time+pbtcor_time+convec_time+diapfl_time
     .           +thermf_time+mxlayr_time+tmsmt2_time+diaacc_time
     .           +io_time
        total_time=total_time+step_time
        total_xio_time=total_xio_time+step_time-io_time
c
        if (mnproc.eq.1) then
          write (lp,'(f12.4,a,i8)')
     .      step_time, '  sec for step ', nstep
          write (lp,'(f12.4,a,i8)')
     .      total_time/(nstep-nstep1),' Avg Time'
          write (lp,'(f12.4,a,i8)')
     .      total_xio_time/(nstep-nstep1),' Avg Time excluding IO'
          write (lp,'(f12.4,a,i8)')
     .      total_time,' Tot Time with contributions:'
          q=100./total_time
          write (lp,'(f12.4,a,i8)') auxil_total_time*q ,'% auxil '
          write (lp,'(f12.4,a,i8)') getflx_total_time*q,'% getflx'
          write (lp,'(f12.4,a,i8)') seaice_total_time*q,'% seaice'
          write (lp,'(f12.4,a,i8)') tmsmt1_total_time*q,'% tmsmt1'
          write (lp,'(f12.4,a,i8)') advdif_total_time*q,'% advdif'
          write (lp,'(f12.4,a,i8)') sfcstr_total_time*q,'% sfcstr'
          write (lp,'(f12.4,a,i8)') momtum_total_time*q,'% momtum'
          write (lp,'(f12.4,a,i8)') pgforc_total_time*q,'% pgforc'
          write (lp,'(f12.4,a,i8)') barotp_total_time*q,'% barotp'
          write (lp,'(f12.4,a,i8)') pbtcor_total_time*q,'% pbtcor'
          write (lp,'(f12.4,a,i8)') convec_total_time*q,'% convec'
          write (lp,'(f12.4,a,i8)') diapfl_total_time*q,'% diapfl'
          write (lp,'(f12.4,a,i8)') thermf_total_time*q,'% thermf'
          write (lp,'(f12.4,a,i8)') mxlayr_total_time*q,'% mxlayr'
          write (lp,'(f12.4,a,i8)') tmsmt2_total_time*q,'% tmsmt2'
          write (lp,'(f12.4,a,i8)') diaacc_total_time*q,'% diaacc'
          write (lp,'(f12.4,a,i8)') io_total_time*q    ,'% IO'
        endif
c
      else
c
c --- ------------------------------------------------------------------
c --- - write time spent for current time step
c --- ------------------------------------------------------------------
c
        io_time=gettime()
        io_total_time=io_total_time+io_time
        step_time=auxil_time +getflx_time+seaice_time+tmsmt1_time
     .           +advdif_time+sfcstr_time+momtum_time+pgforc_time
     .           +barotp_time+pbtcor_time+convec_time+diapfl_time
     .           +thermf_time+mxlayr_time+tmsmt2_time+diaacc_time
     .           +io_time
        total_time=total_time+step_time
        total_xio_time=total_xio_time+step_time-io_time
c
        if (mnproc.eq.1) then
          write (lp,'(f12.4,a,i8)') step_time, '  sec for step ', nstep
        endif
c
      endif
c
      delt1=baclin+baclin
c
      return
      end
