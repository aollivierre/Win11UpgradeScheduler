Function Show-CalendarPicker {
    <#
    .SYNOPSIS
        Shows a WPF calendar picker dialog for date selection
    .DESCRIPTION
        Creates a native WPF calendar control for Windows 11 upgrade scheduling
        Compatible with ALL Windows 10 versions and PowerShell 5.0+
    .PARAMETER MinDate
        Minimum selectable date (default: tomorrow)
    .PARAMETER MaxDate
        Maximum selectable date (default: 90 days from now)
    .PARAMETER DefaultTime
        Default time for the selected date (default: 14:30)
    .OUTPUTS
        DateTime object of selected date/time, or $null if cancelled
    .EXAMPLE
        $selectedDate = Show-CalendarPicker
        $selectedDate = Show-CalendarPicker -MinDate (Get-Date).AddDays(1) -MaxDate (Get-Date).AddDays(60)
    #>
    [CmdletBinding()]
    [OutputType([DateTime])]
    Param(
        [Parameter(Mandatory=$false)]
        [DateTime]$MinDate = (Get-Date).AddDays(1),
        
        [Parameter(Mandatory=$false)]
        [DateTime]$MaxDate = (Get-Date).AddDays(90),
        
        [Parameter(Mandatory=$false)]
        [TimeSpan]$DefaultTime = [TimeSpan]::new(14, 30, 0)  # 2:30 PM
    )
    
    try {
        Write-Log -Message "Loading WPF calendar picker..." -Source 'Show-CalendarPicker'
        
        # Load required assemblies
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        
        # XAML for the calendar picker dialog
        [xml]$xaml = @"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Schedule Windows 11 Upgrade" 
        Height="420" 
        Width="480" 
        WindowStartupLocation="CenterScreen" 
        ResizeMode="NoResize"
        Topmost="True"
        Background="#F3F3F3">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Title -->
        <TextBlock Grid.Row="0" 
                   Text="Select your preferred upgrade date:" 
                   FontFamily="Segoe UI" 
                   FontSize="14" 
                   FontWeight="SemiBold"
                   Foreground="#323130"
                   Margin="0,0,0,15"/>
        
        <!-- Calendar -->
        <Calendar Grid.Row="2" 
                  Name="DatePicker"
                  HorizontalAlignment="Center"
                  VerticalAlignment="Top"
                  FontFamily="Segoe UI"
                  FontSize="12"
                  Margin="0,0,0,20"/>
        
        <!-- Time Selection -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,15">
            <TextBlock Text="Time:" 
                       FontFamily="Segoe UI" 
                       FontSize="12" 
                       VerticalAlignment="Center"
                       Foreground="#323130"
                       Margin="0,0,10,0"/>
            <ComboBox Name="TimePicker" 
                      Width="120" 
                      FontFamily="Segoe UI" 
                      FontSize="12"
                      SelectedIndex="2">
                <ComboBoxItem Content="8:00 AM (Early Morning)" Tag="08:00"/>
                <ComboBoxItem Content="12:00 PM (Lunch Time)" Tag="12:00"/>
                <ComboBoxItem Content="2:30 PM (Afternoon)" Tag="14:30"/>
                <ComboBoxItem Content="5:00 PM (After Hours)" Tag="17:00"/>
                <ComboBoxItem Content="8:00 PM (Evening)" Tag="20:00"/>
                <ComboBoxItem Content="10:00 PM (Late Evening)" Tag="22:00"/>
            </ComboBox>
        </StackPanel>
        
        <!-- Selected Date Display -->
        <TextBlock Grid.Row="4" 
                   Name="SelectedDateText"
                   Text="Selected: Monday, July 15, 2025 at 2:30 PM" 
                   FontFamily="Segoe UI" 
                   FontSize="12"
                   FontStyle="Italic"
                   Foreground="#605E5C"
                   HorizontalAlignment="Center"
                   Margin="0,0,0,10"/>
        
        <!-- Important Notice -->
        <Border Grid.Row="4" 
                Background="#FFF3CD" 
                BorderBrush="#FFEAA7" 
                BorderThickness="1" 
                CornerRadius="4" 
                Padding="10" 
                Margin="0,25,0,15"
                VerticalAlignment="Bottom">
            <TextBlock Text="Note: The upgrade process takes approximately 2 hours to complete and will restart your device multiple times. Please save all work before the scheduled time." 
                      FontFamily="Segoe UI" 
                      FontSize="11"
                      Foreground="#856404"
                      TextWrapping="Wrap"
                      HorizontalAlignment="Center"/>
        </Border>
        
        <!-- Buttons -->
        <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Center">
            <Button Name="CancelButton" 
                    Content="Cancel" 
                    Width="100" 
                    Height="32"
                    Margin="0,0,15,0"
                    FontFamily="Segoe UI"
                    FontSize="12"
                    Background="#E1E1E1"
                    BorderBrush="#D1D1D1"
                    Foreground="#323130"/>
            <Button Name="ScheduleButton" 
                    Content="Schedule Upgrade" 
                    Width="140" 
                    Height="32"
                    FontFamily="Segoe UI"
                    FontSize="12"
                    Background="#0078D4"
                    BorderBrush="#0078D4"
                    Foreground="White"/>
        </StackPanel>
    </Grid>
</Window>
"@
        
        # Parse XAML
        $reader = [System.Xml.XmlNodeReader]::new($xaml)
        $window = [Windows.Markup.XamlReader]::Load($reader)
        
        # Get controls
        $datePicker = $window.FindName("DatePicker")
        $timePicker = $window.FindName("TimePicker")
        $selectedDateText = $window.FindName("SelectedDateText")
        $cancelButton = $window.FindName("CancelButton")
        $scheduleButton = $window.FindName("ScheduleButton")
        
        # Configure calendar
        $datePicker.DisplayDateStart = $MinDate
        $datePicker.DisplayDateEnd = $MaxDate
        $datePicker.SelectedDate = $MinDate
        $datePicker.DisplayDate = $MinDate
        
        # Variables to track user selection
        $script:selectedDateTime = $null
        $script:dialogResult = $false
        
        # Enable the schedule button by default since we have valid defaults
        $scheduleButton.IsEnabled = $true
        
        # Function to update selected date display
        $updateSelectedDateDisplay = {
            if ($datePicker.SelectedDate -and $timePicker.SelectedItem) {
                $selectedDate = $datePicker.SelectedDate
                $timeTag = $timePicker.SelectedItem.Tag
                $timeSpan = [TimeSpan]::Parse($timeTag + ":00")
                $fullDateTime = $selectedDate.Add($timeSpan)
                
                $dayOfWeek = $fullDateTime.ToString('dddd')
                $dateString = $fullDateTime.ToString('MMMM dd, yyyy')
                $timeString = $fullDateTime.ToString('h:mm tt')
                
                $selectedDateText.Text = "Selected: $dayOfWeek, $dateString at $timeString"
                
                # Enable schedule button if date is valid (always enable for valid selections)
                $scheduleButton.IsEnabled = $true
            }
        }
        
        # Event handlers
        $datePicker.Add_SelectedDatesChanged({
            & $updateSelectedDateDisplay
        })
        
        $timePicker.Add_SelectionChanged({
            & $updateSelectedDateDisplay
        })
        
        $scheduleButton.Add_Click({
            if ($datePicker.SelectedDate -and $timePicker.SelectedItem) {
                $selectedDate = $datePicker.SelectedDate
                $timeTag = $timePicker.SelectedItem.Tag
                $timeSpan = [TimeSpan]::Parse($timeTag + ":00")
                $script:selectedDateTime = $selectedDate.Add($timeSpan)
                $script:dialogResult = $true
                $window.Close()
            }
        })
        
        $cancelButton.Add_Click({
            $script:dialogResult = $false
            $window.Close()
        })
        
        # Handle window close
        $window.Add_Closing({
            if (-not $script:dialogResult) {
                $script:selectedDateTime = $null
            }
        })
        
        # Initialize display
        & $updateSelectedDateDisplay
        
        # Show dialog
        Write-Log -Message "Displaying calendar picker dialog" -Source 'Show-CalendarPicker'
        $null = $window.ShowDialog()
        
        # Return result
        if ($script:dialogResult -and $script:selectedDateTime) {
            Write-Log -Message "User selected date/time: $($script:selectedDateTime.ToString('yyyy-MM-dd HH:mm:ss'))" -Source 'Show-CalendarPicker'
            return $script:selectedDateTime
        } else {
            Write-Log -Message "User cancelled calendar picker" -Source 'Show-CalendarPicker'
            return $null
        }
        
    }
    catch {
        Write-Log -Message "Error in calendar picker: $($_.Exception.Message)" -Severity 3 -Source 'Show-CalendarPicker'
        return $null
    }
}