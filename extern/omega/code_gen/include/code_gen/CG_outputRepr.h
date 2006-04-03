// $Id: CG_outputRepr.h,v 1.1.1.1 2000/06/29 19:23:28 dwonnaco Exp $

//*****************************************************************************
// File: CG_outputRepr.h
//
// Purpose:
//     definition of internal representation of String code generation
//     from Omega
//     
// History:
//     04/17/96 - Lei Zhou - created
//
//*****************************************************************************

#ifndef CG_outputRepr_h
#define CG_outputRepr_h

#include <stdio.h>

class CG_outputRepr;                    // forward declaration

#define CG_REPR_NIL         (CG_outputRepr *)NULL

//*****************************************************************************
// class: CG_outputRepr
//
// Purpose:
//    abstract base class of omega codegen internal representation.
//     
// History:
//     04/17/96 - Lei Zhou - created
//
//*****************************************************************************
class CG_outputRepr {
public:
  virtual ~CG_outputRepr() {};

  //---------------------------------------------------------------------------
  // Dump operations
  //---------------------------------------------------------------------------
  virtual void Dump() const = 0; 
  virtual void DumpToFile(FILE *fp = stderr) const = 0;
};


#endif // CG_outputRepr_h
