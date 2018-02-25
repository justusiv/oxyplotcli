Set-StrictMode -Version 3

Describe "New-OxyPlotModel" {

  It "can accept an array of Series objects" {
    $s1 = New-OxyLineSeries -X 1,2,3 -Y 4,5,6
    $s2 = New-OxyLineSeries -X 1,2,3 -Y 4,5,6
    $m = New-OxyPlotModel -Series $s1, $s2
    $m.Series.Count | Should -Be 2
    $m.Series[0] | Should -Be $s1
  }

  It "can create axis objects through -Ax/-Ay style options" {
    $m = New-OxyPlotModel -AxType log -AxMinimum -10
    $m.Axes.Count | Should -Be 1
    $m.Axes[0] | Should -BeOfType [OxyPlot.Axes.LogarithmicAxis]
    $m.Axes[0].Minimum | Should -Be -10
  }

}

Describe "Add-OxyObjectToPlotModel" {

  It "can add an axis" {
    $m = New-OxyPlotModel
    $axis = New-OxyLinearAxis
    Add-OxyObjectToPlotModel $axis $m

    $m.Axes.Count | Should -Be 1
    $m.Axes[0] | Should -BeExactly $axis
  }

  It "can add an annotation" {
    $m = New-OxyPlotModel
    $ann = New-OxyLineAnnotation
    Add-OxyObjectToPlotModel $ann $m

    $m.Annotations.Count | Should -be 1
    $m.Annotations[0] | Should -BeExactly $ann
  }

  It "can add a series and automatically set axes" {
    $m = New-OxyPlotModel
    $s = New-OxyBarSeries
    Add-OxyObjectToPlotModel $s $m

    $m.Axes.Count | Should -Be 2
    $m.Axes[0] | Should -BeOfType [OxyPlot.Axes.LinearAxis]
    $m.Axes[1] | Should -BeOfType [OxyPlot.Axes.CategoryAxis]
  }

  It "can add an axis in the second tier if needed" {
    $m = New-OxyPlotModel

    $s1 = New-OxyLineSeries
    Add-OxyObjectToPlotModel $s1 $m

    $s2 = New-OxyBarSeries
    Add-OxyObjectToPlotModel $s2 $m

    $m.Axes.Count | Should -Be 3
    $m.Axes[2] | Should -BeOfType [OxyPlot.Axes.CategoryAxis]
    $m.Axes[2].PositionTier | Should -Be 1
  }

}
