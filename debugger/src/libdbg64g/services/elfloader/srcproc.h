/**
 * @file
 * @copyright  Copyright 2016 GNSS Sensor Ltd. All right reserved.
 * @author     Sergey Khabarov - sergeykhbr@gmail.com
 * @brief      Source code processor class declaration.
 */

#ifndef __DEBUGGER_SRCPROC_H__
#define __DEBUGGER_SRCPROC_H__

#include "iclass.h"
#include "iservice.h"
#include "coreservices/isrccode.h"

namespace debugger {

typedef int (*disasm_opcode_f)(uint64_t pc,
                                uint32_t code,
                                AttributeType *mnemonic,
                                AttributeType *comment);

class SourceService : public IService,
                      public ISourceCode {
public:
    explicit SourceService(const char *name);
    virtual ~SourceService();

    /** IService interface */
    virtual void postinitService();

    /** ISourceCode interface */
    virtual int disasm(uint64_t pc,
                       AttributeType *data,
                       int offset,
                       AttributeType *mnemonic,
                       AttributeType *comment);

private:
    disasm_opcode_f tblOpcode1_[32];
};

DECLARE_CLASS(SourceService)

}  // namespace debugger

#endif  // __DEBUGGER_SRCPROC_H__
