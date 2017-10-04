      module extra

! hparish adds this routine to calculate the norm of the matrices.
! this routine does not have ANY link to the actual model calculations
! and is only used as a tool to make debugging process easier.

! for info: h.parish@uci.edu

      contains

!HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

      real function EUC_NORM (matx,dim1s,dim1e,dim2s,dim2e,dim3s,dim3e)

!     This subroutine computes Euclidean norm of matrix matx and updates EUC_NORM.
!     dim1s, dim1e, dim2s, dim2e, dim3s, dim3e are indices of start and end.
!     for now EUC_NORM is local to the subdomain, i.e. no global summation over MPI world.

!      USE params
!      INCLUDE 'mpif.h'

      INTEGER          ::  dim1s,dim1e,dim2s,dim2e,dim3s,dim3e,i,j,k
      REAL             ::  x_c, x_sum, x_abs
      REAL, DIMENSION (dim1s:dim1e,dim2s:dim2e,dim3s:dim3e)  :: matx

      x_c   = 0.0
      x_abs = 0.0
      EUC_NORM  = 0.0

      DO k = dim3s, dim3e
       DO j = dim2s, dim2e
        DO i = dim1s, dim1e

         x_abs = matx(i,j,k)**2.0
         x_c   = x_c + x_abs

        ENDDO
       ENDDO
      ENDDO

      EUC_NORM = sqrt ( x_c )

      RETURN
      end function EUC_NORM

!HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

      end module extra
