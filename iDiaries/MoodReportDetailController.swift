//
//  MoodReportDetailController.swift
//  iDiaries
//
//  Created by AlexChow on 16/1/15.
//  Copyright © 2016年 GStudio. All rights reserved.
//

import UIKit
import TEAChart
import FSLineChart

let barChartColors:[UIColor] =
[
    UIColor.redColor(),
    UIColor.orangeColor(),
    UIColor.greenColor(),
    UIColor.cyanColor(),
    UIColor.blueColor(),
    UIColor.purpleColor(),
    UIColor.yellowColor(),
    UIColor.magentaColor(),
    UIColor.brownColor(),
    UIColor.themeColor
]

class MoodReportDetailCell:UITableViewCell
{
    static let reuseId = "MoodReportDetailCell"
    @IBOutlet weak var chartContainer: UIView!
}

class MoodReportSummaryCell:UITableViewCell
{
    static let reuseId = "MoodReportSummaryCell"
    @IBOutlet weak var totalDiariesCountLabel: UILabel!
    @IBOutlet weak var averageMoodsLabel: UILabel!
    @IBOutlet weak var bestMoodLabel: UILabel!
    @IBOutlet weak var badMoodLabel: UILabel!
}

class MoodReportDetailController: UITableViewController
{
    private var charts = [UIView]()
    var report:Report!{
        didSet{
            initLineChartData()
            initStatData()
        }
    }
    private var lineChartViewData:[Float]!
    
    private var monthMoodStat = MonthMoodStat()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsSelection = false
        self.tableView.separatorStyle = .None
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.initCharts()
        let date = DateHelper.generateDate(report.year,month: report.month)
        self.navigationItem.title = MoodReportCell.titleFormatter.stringFromDate(date)
        self.tableView.reloadData()
    }
    
    //MARK: inits
    
    private func initCharts()
    {
        initMoodTrendsChart()
        initMoodStatisticsChart()
    }
    
    private func initLineChartData()
    {
        let days = DateHelper.daysOfMonth(report.year, month: report.month)
        var data = [Float]()
        
        for d in 1...days
        {
            var moodPoint:Float = 0.0
            let moods = report.moods.filter{$0.day == d}
            moods.forEach({ (mood) -> () in
                moodPoint += (mood.mark.info as! Float)
            })
            
            if moodPoint > 0
            {
                let yPoint = moodPoint / Float(moods.count)
                data.append(yPoint)
            }else{
                data.append(data.last ?? 60)
            }
        }
        self.lineChartViewData = data
        
        
    }
    
    struct MonthMoodStat {
        var writeDiaryPersent:Double = 0
        var avgMoodPointEmoji = ""
        var avgMoodPoint:Float = 0
        
        var bestMood:Float = 0
        var bestDay:Int = 1
        var bestMoodEmoji = ""
        
        var lowestMood:Float = 0
        var lowestDay:Int = 1
        var lowestMoodEmoji = ""
        
    }
    
    private func initStatData()
    {
        let monthDays = DateHelper.daysOfMonth(report.year, month: report.month)
        monthMoodStat.writeDiaryPersent = Double(report.diariesCount) / Double(monthDays) * 100
        
        var avgMoodPoint:Float = 0
        self.lineChartViewData.forEach{avgMoodPoint += $0}
        
        monthMoodStat.avgMoodPoint = avgMoodPoint / Float(lineChartViewData.count)
        
        monthMoodStat.avgMoodPointEmoji = MoodReportDetailController.moodValueEmoji(CGFloat(monthMoodStat.avgMoodPoint))
        
        monthMoodStat.bestMood = lineChartViewData.maxElement() ?? 60
        monthMoodStat.bestDay = (lineChartViewData.indexOf(monthMoodStat.bestMood) ?? 0) + 1
        monthMoodStat.bestMoodEmoji = MoodReportDetailController.moodValueEmoji(CGFloat(monthMoodStat.bestMood))
        
        monthMoodStat.lowestMood = lineChartViewData.minElement() ?? 60
        monthMoodStat.lowestDay = (lineChartViewData.indexOf(monthMoodStat.lowestMood) ?? 0) + 1
        monthMoodStat.lowestMoodEmoji = MoodReportDetailController.moodValueEmoji(CGFloat(monthMoodStat.lowestMood))
        
    }
    
    static func moodValueEmoji(value:CGFloat) -> String
    {
        if value <= 30
        {
            return "😞"
        }else if value < 60
        {
            return "☹️"
        }else if value < 70
        {
            return "🙂"
        }else if value < 88
        {
            return "😀"
        }else
        {
            return "😄"
        }
    }
    
    private func initMoodTrendsChart()
    {
        let lineChartTitle = UILabel()
        lineChartTitle.text = "MOOD_TRENDS_TITLE".localizedString
        lineChartTitle.sizeToFit()
        lineChartTitle.textColor = UIColor.lightGrayColor()
        lineChartTitle.center = CGPointMake(self.view.center.x - 10, -10)
        let frame = CGRectMake(10, 23, tableView.contentSize.width - 20, tableView.contentSize.width - 56)
        let lineChart = FSLineChart(frame: frame)
        lineChart.addSubview(lineChartTitle)
        lineChart.displayDataPoint = true
        func getLabel(index:UInt) -> String{
            return "\(index + 1)"
        }
        lineChart.horizontalGridStep = 7
        lineChart.verticalGridStep = 5
        lineChart.labelForIndex = getLabel
        lineChart.labelForValue = MoodReportDetailController.moodValueEmoji
        lineChart.fillColor = nil
        
        charts.append(lineChart)
    }
    
    private func initMoodStatisticsChart()
    {
        let barWidth:CGFloat = 23
        let chartTitle = UILabel()
        let barChart = TEABarChart()
        let cellWidth = tableView.contentSize.width + 4
        chartTitle.text = "MOOD_STATISTICS_TITLE".localizedString
        chartTitle.sizeToFit()
        chartTitle.textColor = UIColor.lightGrayColor()
        chartTitle.center = CGPointMake(self.view.center.x - 10, -13)
        barChart.addSubview(chartTitle)
        
        let arr = MoodMarks.map{$0.id}
        barChart.data = arr.map{report.moodsMap[$0] ?? 0}
        barChart.xLabels = arr.map{ id -> String in
            if let mark = getDiaryMark("\(id)")
            {
                return "\(mark.emoji)"
            }else
            {
                return ""
            }
            }.filter{String.isNullOrEmpty($0) == false}
        let barSpace = (cellWidth - CGFloat(arr.count) * barWidth) / CGFloat(arr.count)
        barChart.barSpacing = Int(barSpace)
        barChart.barColors = barChartColors.messArrayUp()
        charts.append(barChart)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.report == nil ? 0 : 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        // Configure the cell...
        if indexPath.row < charts.count
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MoodReportDetailCell.reuseId, forIndexPath: indexPath) as! MoodReportDetailCell
            let chart = charts[indexPath.row]
            cell.addSubview(chart)
            return cell
        }else
        {
            let cell = tableView.dequeueReusableCellWithIdentifier(MoodReportSummaryCell.reuseId, forIndexPath: indexPath) as! MoodReportSummaryCell
            cell.totalDiariesCountLabel.text = String(format: "%d(%.0f%%)",report.diariesCount, monthMoodStat.writeDiaryPersent)
            cell.averageMoodsLabel.text = String(format: "%.0f%@", monthMoodStat.avgMoodPoint,monthMoodStat.avgMoodPointEmoji)
            cell.bestMoodLabel.text = String(format: "DAY_MOOD_EMOJI_FORMAT".localizedString, monthMoodStat.bestDay,monthMoodStat.bestMood,monthMoodStat.bestMoodEmoji)
            cell.badMoodLabel.text = String(format: "DAY_MOOD_EMOJI_FORMAT".localizedString, monthMoodStat.lowestDay,monthMoodStat.lowestMood,monthMoodStat.lowestMoodEmoji)
            return cell
        }
    }

    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < charts.count
        {
            let frame = CGRectMake(10, 23, cell.frame.size.width - 20, cell.frame.size.width - 67)
            if let chart = charts[indexPath.row] as? TEABarChart
            {
                chart.frame = frame
                chart.layoutSubviews()
            }else if let chart = charts[indexPath.row] as? FSLineChart
            {
                chart.frame = frame
                chart.setChartData(self.lineChartViewData)
            }
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 2
        {
            return UITableViewAutomaticDimension
        }
        return tableView.contentSize.width
    }
    
    static func showReport(rootController:UIViewController, report:Report)
    {
        let controller = instanceFromStoryBoard("MoodReport", identifier: "MoodReportDetailController") as! MoodReportDetailController
        controller.report = report
        rootController.navigationController!.pushViewController(controller, animated: true)
    }

}
