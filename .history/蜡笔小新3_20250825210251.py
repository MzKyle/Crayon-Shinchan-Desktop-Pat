import sys
import os
import random
import traceback
from PyQt5 import QtWidgets, QtGui, QtCore

def excepthook(exc_type, exc_value, exc_tb):
    traceback.print_exception(exc_type, exc_value, exc_tb)
    sys.exit(1)

sys.excepthook = excepthook

class DeskPet(QtWidgets.QLabel):
    def __init__(self):
        super().__init__()
        self.initUI()
        self.childPets = []
        self.isDragging = False
        self.drag_position = QtCore.QPoint()

    def initUI(self):
        self.setWindowFlags(QtCore.Qt.FramelessWindowHint | QtCore.Qt.WindowStaysOnTopHint)
        self.setAttribute(QtCore.Qt.WA_TranslucentBackground)
        self.setGeometry(1000, 500, 130, 130)
        self.currentAction = self.startIdle
        self.timer = QtCore.QTimer(self)
        self.timer.timeout.connect(self.updateAnimation)
        self.startIdle()
        self.setContextMenuPolicy(QtCore.Qt.CustomContextMenu) #禁用默认右键菜单
        self.customContextMenuRequested.connect(self.showMenu)
        self.setCursor(QtCore.Qt.OpenHandCursor)

    def mousePressEvent(self, event):
        if event.button() == QtCore.Qt.LeftButton:
            self.isDragging = True
            self.drag_position = event.globalPos() - self.pos()
            self.prevAction = self.currentAction
            event.accept()

    def mouseMoveEvent(self, event):
        if QtCore.Qt.LeftButton and self.isDragging:
            self.move(event.globalPos() - self.drag_position)
            event.accept()

    def mouseReleaseEvent(self, event):
        if event.button() == QtCore.Qt.LeftButton:
            self.isDragging = False

            self.prevAction()  # 或者 self.startIdle(), 根据之前的动作恢复状态
            event.accept()

    def loadImages(self, path):
        """加载指定路径的PNG图片，并按文件名中的数字顺序排序"""
        # 获取所有.png文件
        files = [f for f in os.listdir(path) if f.endswith('.png')]
        # 按文件名中的数字排序（例如：eat_0001.png, eat_0002.png...）
        files.sort(key=lambda x: int(''.join(filter(str.isdigit, x))))
        # 返回排序后的QPixmap列表
        return [QtGui.QPixmap(os.path.join(path, f)) for f in files]

    def startIdle(self):
        # 清除之前的定时器连接
        try:
            self.timer.timeout.disconnect()
        except TypeError:
            pass

        self.setFixedSize(130, 130)
        self.currentAction = self.startIdle
        self.images = self.loadImages("home/kyle/labi/LaBiDeskPet/resourcexianzhi")
        self.currentImage = 0
        # 重新连接通用动画更新
        self.timer.timeout.connect(self.updateAnimation)
        self.timer.start(100)
        self.moveSpeed = 0
        self.movingDirection = 0

    def startWalk(self):
        self.setFixedSize(130, 130)
        if not self.isDragging:
            self.currentAction = self.startWalk
            direction = random.choice(["zuo", "you"])
            self.images = self.loadImages(f"/home/kyle/labi/LaBiDeskPet/resourcesanbu/{direction}")
            self.currentImage = 0
            self.movingDirection = -1 if direction == "zuo" else 1
            self.moveSpeed = 10
            self.timer.start(100)

    def movePet(self):
        screen = QtWidgets.QDesktopWidget().screenGeometry()
        new_x = self.x() + self.movingDirection * self.moveSpeed
        if new_x < 10:
            new_x = 10
            self.movingDirection *= -1
            self.updateWalkDirection()
        elif new_x > screen.width() - self.width() - 10:
            new_x = screen.width() - self.width() - 10
            self.movingDirection *= -1
            self.updateWalkDirection()

        # 更新主桌宠位置
        self.move(new_x, self.y())

        # 使用全局坐标进行碰撞检测
        main_rect = self.frameGeometry()

        # 过滤有效的小白实例
        valid_children = []
        for child in self.childPets:
            if isinstance(child, XiaobaiWindow) and child.isVisible():
                xiaobai_rect = child.frameGeometry()
                if main_rect.intersects(xiaobai_rect):
                    child.close()
                    self.startMeet()
                valid_children.append(child)
        self.childPets = valid_children  # 更新为有效子窗口

    def updateWalkDirection(self):
        """更新行走方向并加载对应图片"""
        self.timer.stop()
        direction = "zuo" if self.movingDirection == -1 else "you"
        self.images = self.loadImages(f"/home/kyle/labi/LaBiDeskPet/resourcesanbu/{direction}")
        if not self.images:
            return
        self.currentImage = 0
        self.timer.start(100)

    def startMeet(self):
        self.setFixedSize(150, 150)
        self.currentAction = self.startMeet
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcemeet")
        self.currentImage = 0
        self.moveSpeed = 0
        self.movingDirection = 0
        self.timer.start(30)

    def startFall(self):
        self.setFixedSize(150, 150)
        self.currentAction = self.startFall
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcexialuo")
        self.currentImage = 0
        self.movingDirection = 0
        self.moveSpeed = 5
        self.stopOtherActions()
        self.timer.start(30)

    def stopOtherActions(self):
        self.timer.stop()
        if self.currentAction == self.startWalk:
            self.changeDirectionTimer.stop()  # 停止方向判定定时器
            self.startIdle()
        elif self.currentAction == self.startFall:
            pass
        else:
            self.startIdle()

    def updateAnimation(self):
        if self.images:
            if self.currentAction == self.sleep:  # 睡眠状态特殊处理
                if self.currentImage >= len(self.images) - 1:  # 到达最后一帧
                    self.timer.stop()
                else:
                    self.currentImage += 1
            elif self.currentAction == self.eating:
                if self.eating_loop:
                    # 循环阶段（122开始）
                    loop_start = 122
                    self.currentImage = loop_start + (self.currentImage - loop_start + 1) % (
                                len(self.images) - loop_start)
                else:
                    # 首次播放阶段
                    if self.currentImage < len(self.images) - 1:
                        self.currentImage += 1
                    else:
                        # 到达结尾自动开始循环
                        self.eating_loop = True
                        self.currentImage = 122 - 1  # 下一帧自动+1到122
                self.setPixmap(self.images[self.currentImage])

            else:  # 其他状态保持循环
                self.currentImage = (self.currentImage + 1) % len(self.images)

            self.setPixmap(self.images[self.currentImage])

        # 原有的移动逻辑保持不变
        if hasattr(self, 'movingDirection'):
            if self.currentAction == self.startFall:
                self.fallPet()
            else:
                self.movePet()


    def fallPet(self):
        self.setFixedSize(130, 130)
        screen = QtWidgets.QDesktopWidget().screenGeometry()
        new_y = self.y() + self.moveSpeed
        if new_y > screen.height() - self.height() - 10:
            new_y = screen.height() - self.height() - 10
            self.timer.stop()
            self.startIdle()
        self.move(self.x(), new_y)

    def showMenu(self, position):
        menu = QtWidgets.QMenu()
        if self.currentAction == self.sleep:
            menu.addAction("偷吃宵夜", self.Snack)
            menu.addAction("唤醒", self.WakeUp)
            menu.addSeparator()
            menu.addAction("隐藏", self.minimizeWindow)
            menu.addAction("退出", self.close)
        else:
            menu.addAction("散步", self.startWalk)
            menu.addAction("下落", self.startFall)
            menu.addAction("运动", self.exercise)
            menu.addAction("吃饭", self.eating)
            menu.addAction("睡觉", self.sleep)
            menu.addAction("屁屁舞", self.pipi)
            menu.addAction("动感光波！", self.transform)
            menu.addAction("呼唤小白", self.summonXiaobai)
            menu.addSeparator()
            menu.addAction("停止", self.startIdle)
            menu.addAction("隐藏", self.minimizeWindow)
            menu.addAction("退出", self.close)
        menu.exec_(self.mapToGlobal(position))

    def Snack(self):
        # 清除之前的定时器连接
        self.timer.timeout.disconnect()

        self.setFixedSize(400, 200)
        self.currentAction = self.Snack
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcesnack")
        if not self.images:
            return

        self.currentImage = 0
        # 专用动画更新连接
        self.timer.timeout.connect(self._update_snack)
        self.timer.start(20)

    def _update_snack(self):
        """零食动画专用更新"""
        if self.currentAction != self.Snack:
            return

        if self.currentImage < len(self.images) - 1:
            self.currentImage += 1
            self.setPixmap(self.images[self.currentImage])
        else:
            self.timer.stop()
            # 显示最后一帧并启动过渡
            self.setPixmap(self.images[-1])
            QtCore.QTimer.singleShot(1000, self._start_sleep_transition)

    def _start_sleep_transition(self):
        """启动睡眠过渡"""
        if self.currentAction == self.Snack:
            # 清理残留连接
            self.timer.timeout.disconnect()
            self.sleep()


    def transform(self):
        self.setFixedSize(160, 130)
        self.currentAction = self.transform
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcexiandanchaoren")
        self.currentImage = 0
        self.timer.start(10)
        self.moveSpeed = 0
        self.movingDirection = 0

    def pipi(self):
        self.setFixedSize(300, 130)
        self.currentAction = self.pipi
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcepipi")
        self.currentImage = 0
        self.timer.start(25)
        self.moveSpeed = 0
        self.movingDirection = 0

    def exercise(self):
        self.setFixedSize(150,180 )
        self.currentAction = self.exercise
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourceyundong")
        self.currentImage = 0
        self.timer.start(125)
        self.moveSpeed = 0
        self.movingDirection = 0

    def eating(self):
        self.setFixedSize(160, 90)
        self.currentAction = self.eating
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourceeat")
        if not self.images or len(self.images) < 122:  # 强化长度检查
            return
        self.currentImage = 0
        self.eating_loop = False
        self.timer.start(25)

    def _start_eating_loop(self):
        """更严谨的循环启动检查"""
        if self.currentAction != self.eating:  # 确保仍在进食状态
            return

        if len(self.images) >= 122 and self.currentImage == len(self.images) - 1:
            self.eating_loop = True
            self.currentImage = 122 - 1  # 从122帧开始（因为updateAnimation会立即+1）

    def sleep(self):
        # 清除所有定时器连接
        try:
            self.timer.timeout.disconnect()
        except TypeError:
            pass

        sleep_images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcesleep")
        if not sleep_images:
            return

        # 初始化睡眠动画参数
        self.setFixedSize(sleep_images[0].width(), sleep_images[0].height())
        self.currentAction = self.sleep
        self.images = sleep_images
        self.currentImage = 0

        # 连接专用睡眠动画更新
        self.timer.timeout.connect(self._update_sleep)
        self.timer.start(20)

    def _update_sleep(self):
        """睡眠动画专用更新"""
        if self.currentAction != self.sleep:
            return

        if self.currentImage < len(self.images) - 1:
            self.currentImage += 1
            self.setPixmap(self.images[self.currentImage])
        else:
            # 保持最后一帧
            self.timer.stop()
            self.setPixmap(self.images[-1])

    def showWakeUpMenu(self):
        self.setFixedSize(130, 130)
        self.sleeping = True
        menu = QtWidgets.QMenu()
        menu.addAction("唤醒", self.wakeUp)
        menu.exec_(self.mapToGlobal(self.pos()))

    def WakeUp(self):
        # 清除之前的定时器连接
        try:
            self.timer.timeout.disconnect()
        except TypeError:
            pass

        wake_images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcewaken")
        if not wake_images:
            return

        # 初始化唤醒参数
        self.setFixedSize(wake_images[0].width(), wake_images[0].height())
        self.currentAction = self.WakeUp
        self.images = wake_images
        self.currentImage = 0

        # 连接专用动画更新
        self.timer.timeout.connect(self._update_wake)
        self.timer.start(30)

    def _update_wake(self):
        """唤醒动画专用更新"""
        if self.currentAction != self.WakeUp:
            return

        if self.currentImage < len(self.images) - 1:
            self.currentImage += 1
            self.setPixmap(self.images[self.currentImage])
        else:
            self.timer.stop()
            self.finishWakeUp()

    def finishWakeUp(self):
        # 清理唤醒状态并启动闲置
        self.startIdle()  # 直接调用startIdle来完整初始化
        self.setFixedSize(130, 130)  # 确保尺寸正确

    def summonXiaobai(self):
        xiaobai = XiaobaiWindow()
        xiaobai.show()
        self.childPets.append(xiaobai)

        # 使用弱引用和异常处理的安全移除方式
        from weakref import ref
        weak_self = ref(self)
        weak_xiaobai = ref(xiaobai)

    def closeEvent(self, event):
        for child in self.childPets:
            child.close()  # 关闭所有子窗口
        super().closeEvent(event)

    def minimizeWindow(self):
        self.showMinimized()

class XiaobaiWindow(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.initUI()

    def initUI(self):
        self.setWindowFlags(QtCore.Qt.FramelessWindowHint | QtCore.Qt.WindowStaysOnTopHint)
        self.setAttribute(QtCore.Qt.WA_TranslucentBackground)
        self.setGeometry(500, 500, 125, 100)
        self.timer = QtCore.QTimer(self)
        self.timer.timeout.connect(self.updateAnimation)
        self.images = self.loadImages("/home/kyle/labi/LaBiDeskPet/resourcexiaobai")
        self.currentImage = 0
        self.timer.start(20)
        self.dragPosition = QtCore.QPoint()
        self.label = QtWidgets.QLabel(self)
        self.label.setGeometry(0, 0, 140, 100)

    def mousePressEvent(self, event):
        if event.button() == QtCore.Qt.LeftButton:
            self.dragPosition = event.globalPos() - self.frameGeometry().topLeft()
            event.accept()

    def mouseMoveEvent(self, event):
        if event.buttons() == QtCore.Qt.LeftButton:
            self.move(event.globalPos() - self.dragPosition)
            event.accept()

    def showMenu(self, position):
        menu = QtWidgets.QMenu()
        menu.addAction("隐藏", self.minimizeWindow)
        menu.addAction("回去", self.close)
        menu.exec_(self.mapToGlobal(position))

    def loadImages(self, path):
        """加载指定路径的PNG图片，并按文件名中的数字顺序排序"""
        # 获取所有.png文件
        files = [f for f in os.listdir(path) if f.endswith('.png')]
        # 按文件名中的数字排序（例如：eat_0001.png, eat_0002.png...）
        files.sort(key=lambda x: int(''.join(filter(str.isdigit, x))))
        # 返回排序后的QPixmap列表
        return [QtGui.QPixmap(os.path.join(path, f)) for f in files]

    def updateAnimation(self):
        self.label.setPixmap(self.images[self.currentImage])
        self.currentImage = (self.currentImage + 1) % len(self.images)

    def minimizeWindow(self):
        self.showMinimized()

    def eventFilter(self, obj, event):
        if event.type() == QtCore.QEvent.ContextMenu:
            self.showMenu(event.pos())
            return True
        return super().eventFilter(obj, event)

    def showEvent(self, event):
        self.installEventFilter(self)

    def closeEvent(self, event):
        self.timer.stop()
        super().closeEvent(event)

if __name__ == "__main__":
    import os

    # 获取脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)  # 设置工作目录

    app = QtWidgets.QApplication(sys.argv)
    pet = DeskPet()
    pet.show()
    sys.exit(app.exec_())