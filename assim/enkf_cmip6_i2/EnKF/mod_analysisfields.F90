!KAL -- this module allows us to fine-tune the fields
!KAL -- we wish to include in tha analysis. The new
!KAL -- layout of the EnKF makes it possible to specify fields
!KAL -- to analyze at run-time rather than at compile-time
!KAL -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
!KAL --
!KAL -- Module variables:
!KAL --    numfields   - total number of fields to process
!KAL --    fieldnames  - the names of the fields we wish to analyze
!KAL --    fieldlevel  - the levels of the associated fields
!KAL --
!KAL -- Ex: If we only want to assimilate temperatures in layer
!KAL --     one and two, numfields, fieldnames and fieldlevel 
!KAL --     would look like:
!KAL --
!KAL --     numfields=2                                 
!KAL --     fieldnames (1)='temp', fieldnames (2)='temp'
!KAL --     fieldlevel (1)=     1, fieldlevel (2)=2
!KAL -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
!KAL -- The file "analysisfields.in" specifies the fields to 
!KAL -- inlude in the analysis. Format of one line is fieldname
!KAL -- first layer and last layer, example
!KAL --
!KAL -- fldname   1 22
!KAL -- 12345678901234567890123456789012345678901234567890
!KAL --
!KAL -- Fortran format for one line is '(a8,2i3)'
!KAL --
!KAL -- Example: to specify that we want temperature and salinity 
!KAL --          in layers 1..22 to be updated, as well as 
!KAL --          ice concentration (layer 0), specify:
!KAL --
!KAL -- saln      1 22
!KAL -- temp      1 22
!KAL -- hice      0  0
!KAL -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

module mod_analysisfields

character(len=*), parameter :: infile='analysisfields.in'
integer :: numfields
character(len=8), dimension(:), allocatable:: fieldnames
integer         , dimension(:), allocatable:: fieldlevel 
character(len=2), dimension(:), allocatable:: rstcode

contains

   integer function get_nrfields()
#if defined (QMPI)
   use qmpi
#else
   use qmpi_fake
#endif
   implicit none
   integer :: ios,first,last
   logical :: ex
   character(len=9) :: char9
   character(len=2) :: char2

   inquire(exist=ex,file=infile)
   if (.not. ex) then
      if (master) print *,'Could not find '//infile
      call stop_mpi()
   end if

   open(10,status='old',form='formatted',file=infile)
   ios=0
   get_nrfields=0
   do while (ios==0)
      read(10,100,iostat=ios) char9,first,last,char2
      if (ios==0) get_nrfields=get_nrfields+last-first+1
   end do
   close(10)
   100 format (a9,2i3,a2)
   end function

   subroutine get_analysisfields()
#if defined (QMPI)
   use qmpi
#else
   use qmpi_fake
#endif
   implicit none
   integer :: first,last,k,nfld,ios
   logical :: ex
   character(len=9) :: char9
   character(len=2) :: char2

   numfields=get_nrfields()
   if (master) print *,'numfields is ',numfields
   if (numfields<=0 .or.numfields > 16000) then !
      if (master) print *,'numfields is higher than max allowed setting or = 0'
      call stop_mpi()
   end if
   allocate(fieldnames(numfields))
   allocate(fieldlevel(numfields))
   allocate(rstcode(numfields))


   inquire(exist=ex,file=infile)
   if (.not. ex) then
      if (master) print *,'Could not find '//infile
      call stop_mpi()
   end if

   open(10,status='old',form='formatted',file=infile)
   ios=0
   nfld=0
   do while (ios==0)
      read(10,100,iostat=ios) char9,first,last,char2
      if (ios==0) then
         do k=first,last
            fieldnames (nfld+k-first+1)=char9
            fieldlevel (nfld+k-first+1)=k
            rstcode (nfld+k-first+1)=char2
         end do
         nfld=nfld+last-first+1
      end if
   end do
   close(10)
   100 format (a9,2i3,a2)

   if (nfld/=numfields) then
      if (master) print *,'An error occured when reading '//infile
      call stop_mpi()
   end if

   ! List fields used in analysis
   do k=1,numfields
      if (master) print *,fieldnames(k),fieldlevel(k),rstcode(k)
   end do

   end subroutine
end module mod_analysisfields






