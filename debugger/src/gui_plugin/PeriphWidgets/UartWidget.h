/**
 * @file
 * @copyright  Copyright 2016 GNSS Sensor Ltd. All right reserved.
 * @author     Sergey Khabarov - sergeykhbr@gmail.com
 * @brief      Serial console emulator.
 */

#pragma once

#include "api_core.h"   // MUST BE BEFORE QtWidgets.h or any other Qt header.
#include "attribute.h"
#include "igui.h"
#include "coreservices/irawlistener.h"
#include "coreservices/iserial.h"

#include "MainWindow/UnclosableWidget.h"
#include "UartEditor.h"
#include <QtWidgets/QWidget>

namespace debugger {

class UartWidget : public UnclosableWidget {
    Q_OBJECT
public:
    UartWidget(IGui *igui, QWidget *parent = 0);
    
signals:
    void signalPostInit(AttributeType *cfg);

private slots:
    void slotPostInit(AttributeType *cfg);

private:
    UartEditor *editor_;
};

}  // namespace debugger
