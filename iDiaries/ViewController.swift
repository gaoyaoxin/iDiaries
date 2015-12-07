//
//  ViewController.swift
//  iDiaries
//
//  Created by AlexChow on 15/12/2.
//  Copyright © 2015年 GStudio. All rights reserved.
//

import UIKit
import KKGestureLockView
import MJRefresh

enum ViewControllerMode
{
    case NewDiaryMode
    case DiaryListMode
}

let SegueShowTimeMailController = "ShowTimeMailController"
let SegueShowEditView = "ShowEditView"
let SegueShowUserSetting = "ShowUserSettingController"

//MARK:ViewController
class ViewController: UITableViewController, KKGestureLockViewDelegate{
    var mode:ViewControllerMode = .NewDiaryMode{
        didSet{
            if tableView != nil
            {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.updateTableViewHeader()
                    self.updateTableViewFooter()
                    self.tableView.reloadData()
                })
            }
        }
    }
    
    private let diaryShot:UIImageView = UIImageView(image: UIImage(named: "diary_shot"))
    
    //MARK: life process
    override func viewDidLoad() {
        super.viewDidLoad()
        ColorSets.navicationBarTintColor = UIColor.whiteColor()
        ColorSets.navicationBarColor = (self.navigationController?.navigationBar.barTintColor!)!
        changeNavigationBarColor()
        tableView.rowHeight = UITableViewAutomaticDimension;
        tableView.estimatedRowHeight = 48;
        navigationItem.rightBarButtonItem?.badgeBGColor = UIColor.orangeColor()
        navigationItem.rightBarButtonItem?.badge.layer.cornerRadius = 10
        updateTableViewHeader()
        initDiaryShot()
        self.tableView.reloadData()
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        TimeMailService.sharedInstance.refreshTimeMailBox { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.rightBarButtonItem?.badgeValue = "\(TimeMailService.sharedInstance.notReadMailCount)"
            })
        }
    }
    
    private func initDiaryShot()
    {
        let height:CGFloat = 196
        let width:CGFloat = 96
        diaryShot.frame = CGRectMake((self.view.frame.width - width)/2, -1000, width, height)
        self.view.addSubview(diaryShot)
    }

    private func animationSaveDiary()
    {
        let startPos = CGPointMake(diaryShot.frame.origin.x + diaryShot.frame.width/2, self.view.frame.height - 72)
        UIAnimationHelper.flyToTopForView(startPos,view: diaryShot)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    private func updateTableViewHeader()
    {
        let imageName = mode == .DiaryListMode ? "new_diary" : "diary"
        tableView.separatorStyle = mode == .DiaryListMode ? .SingleLine : .None
        let image = UIImage(named: imageName)!
        let header = MJRefreshGifHeader { () -> Void in
            self.tableView.mj_header.endRefreshing()
            self.switchDiaryMode()
        }
        header.lastUpdatedTimeLabel?.hidden = true
        header.stateLabel?.hidden = true
        header.setImages([image], forState: .Idle)
        tableView.mj_header = header
    }
    
    private func updateTableViewFooter()
    {
        if mode == .DiaryListMode && DiaryListManager.sharedInstance.diaryListItemCount == 0
        {
            let footer = NothingViewFooter.instanceFromXib()
            footer.messageLabel.text = NSLocalizedString("NO_DIARY_HERE", comment: "")
            footer.frame = tableView.bounds
            tableView.tableFooterView = footer
        }else
        {
            tableView.tableFooterView = UIView()
        }
    }
    
    private func openDiaries()
    {
        self.makeToastActivity()
        DiaryListManager.sharedInstance.refreshDiary({ () -> Void in
            self.hideToastActivity()
            self.mode = .DiaryListMode
        })
    }
    
    private func switchDiaryMode()
    {
        if mode == .NewDiaryMode
        {
            if DiaryListManager.sharedInstance.isLocked
            {
                if DiaryService.sharedInstance.hasPassword()
                {
                    PasswordLocker.showValidateLocker(self){
                        DiaryListManager.sharedInstance.unlockDiary()
                        self.openDiaries()
                    }
                }else
                {
                    PasswordLocker.showSetPasswordLocker(self){ newPsw in
                        DiaryListManager.sharedInstance.unlockDiary()
                        self.openDiaries()
                    }
                }
            }else
            {
                openDiaries()
            }
            
        }else
        {
            self.mode = .NewDiaryMode
        }
    }
    
    func saveDiary() {
        if let notReady = NewDiaryCellManager.sharedInstance.notReadyForSaveCell()
        {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: notReady.index, inSection: 0), atScrollPosition: .None, animated: true)
            notReady.cell.shakeAnimationForView(7)
            SystemSoundHelper.vibrate()
        }else
        {
            NewDiaryCellManager.sharedInstance.saveNewDiary()
            animationSaveDiary()
        }
    }
    
    @IBAction func timeMailClick(sender: AnyObject) {
        
        if DiaryListManager.sharedInstance.isLocked
        {
            if DiaryService.sharedInstance.hasPassword()
            {
                PasswordLocker.showValidateLocker(self){
                    DiaryListManager.sharedInstance.unlockDiary()
                    self.performSegueWithIdentifier(SegueShowTimeMailController, sender: self)
                }
            }else
            {
                PasswordLocker.showSetPasswordLocker(self){ newPsw in
                    DiaryListManager.sharedInstance.unlockDiary()
                    self.performSegueWithIdentifier(SegueShowTimeMailController, sender: self)
                }
            }
        }else
        {
            self.performSegueWithIdentifier(SegueShowTimeMailController, sender: self)
        }
    }
    
    @IBAction func userSettingClick(sender: AnyObject)
    {
        if DiaryListManager.sharedInstance.isLocked
        {
            if DiaryService.sharedInstance.hasPassword()
            {
                PasswordLocker.showValidateLocker(self){
                    DiaryListManager.sharedInstance.unlockDiary()
                    self.performSegueWithIdentifier(SegueShowUserSetting, sender: self)
                }
            }else
            {
                PasswordLocker.showSetPasswordLocker(self){ newPsw in
                    DiaryListManager.sharedInstance.unlockDiary()
                    self.performSegueWithIdentifier(SegueShowUserSetting, sender: self)
                }
            }
        }else
        {
            self.performSegueWithIdentifier(SegueShowUserSetting, sender: self)
        }
    }
    
    //MARK:Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == SegueShowEditView
        {
            let vc = segue.destinationViewController as! EditMainContentViewController
            vc.mainContentCell = sender as! NewDiaryTextContentCell
            
        }
    }
    
    //MARK:TableView delegate
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch mode
        {
        case .NewDiaryMode:
            return NewDiaryCellManager.sharedInstance.newDiaryCellsCount
        case .DiaryListMode:
            return DiaryListManager.sharedInstance.diaryListItemCount
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if mode == .NewDiaryMode
        {
            return NewDiaryCellManager.sharedInstance.getNewDiaryCell(self, row: indexPath.row)
        }else
        {
            let contentCell = tableView.dequeueReusableCellWithIdentifier(DiaryContentCell.reuseId,forIndexPath: indexPath) as! DiaryContentCell
            contentCell.diary = DiaryListManager.sharedInstance.diaries[indexPath.row]
            contentCell.update()
            return contentCell
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if mode == .NewDiaryMode
        {
            return NewDiaryCellManager.sharedInstance.getCellHeight(indexPath.row)
            
        }
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        if mode == .DiaryListMode
        {
            return .Delete
        }
        return .None
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let diary = DiaryListManager.sharedInstance.removeDiary(indexPath.row)
        DiaryService.sharedInstance.deleteDiary(diary)
        tableView.reloadData()
    }
 
}
