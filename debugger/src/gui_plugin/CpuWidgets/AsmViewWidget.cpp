/**
 * @file
 * @copyright  Copyright 2016 GNSS Sensor Ltd. All right reserved.
 * @author     Sergey Khabarov - sergeykhbr@gmail.com
 * @brief      Disassembler viewer form.
 */

#include "AsmArea.h"
#include "AsmControl.h"
#include "AsmViewWidget.h"
#include "moc_AsmViewWidget.h"

#include <memory>

namespace debugger {

AsmViewWidget::AsmViewWidget(IGui *igui, QWidget *parent) 
    : UnclosableWidget(parent) {
    igui_ = igui;

    gridLayout = new QGridLayout(this);
    gridLayout->setSpacing(4);
    gridLayout->setHorizontalSpacing(10);
    gridLayout->setVerticalSpacing(0);
    gridLayout->setContentsMargins(4, 4, 4, 4);
    setLayout(gridLayout);

    AsmControl *pctrl = new AsmControl(this);

    AsmArea *parea = new AsmArea(igui, this);
    gridLayout->addWidget(pctrl , 0, 0);
    gridLayout->addWidget(parea, 1, 0);
    gridLayout->setRowStretch(1, 10);

    connect(this, SIGNAL(signalPostInit(AttributeType *)),
            parea, SLOT(slotPostInit(AttributeType *)));

    connect(this, SIGNAL(signalUpdateByTimer()),
            parea, SLOT(slotUpdateByTimer()));
}

void AsmViewWidget::slotPostInit(AttributeType *cfg) {
    emit signalPostInit(cfg);
}

void AsmViewWidget::slotUpdateByTimer() {
    if (!isVisible()) {
        return;
    }
    emit signalUpdateByTimer();
}

}  // namespace debugger
