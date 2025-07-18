function Show-EnhancedCalendarPicker {
    <#
    .SYNOPSIS
        Enhanced calendar picker with same-day scheduling options
    .DESCRIPTION
        Shows Tonight options (8PM, 10PM, 11PM) and Tomorrow quick picks
    #>
    
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    
    [xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Schedule Windows 11 Upgrade"
        Height="580" Width="420"
        WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize"
        Background="#F0F0F0">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,10">
            <TextBlock Text="Schedule Your Windows 11 Upgrade" 
                       FontSize="18" FontWeight="Bold"
                       HorizontalAlignment="Center"/>
            <TextBlock Text="Must be completed within 14 days" 
                       FontSize="12" Foreground="DarkRed"
                       HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>
        
        <!-- Quick Options Header -->
        <TextBlock Grid.Row="1" Text="Quick Scheduling Options:" 
                   FontSize="14" FontWeight="SemiBold" Margin="0,0,0,5"/>
        
        <!-- Tonight/Tomorrow Options -->
        <Border Grid.Row="2" BorderBrush="#CCCCCC" BorderThickness="1" 
                Background="White" CornerRadius="5" Margin="0,0,0,10">
            <StackPanel Margin="10">
                <!-- Tonight Options -->
                <TextBlock Text="Tonight" FontWeight="Bold" Margin="0,0,0,5"/>
                <WrapPanel Name="TonightPanel" Margin="0,0,0,10">
                    <RadioButton Name="Tonight8PM" Content="8:00 PM" 
                                GroupName="QuickPick" Margin="0,0,15,0"/>
                    <RadioButton Name="Tonight10PM" Content="10:00 PM" 
                                GroupName="QuickPick" Margin="0,0,15,0"/>
                    <RadioButton Name="Tonight11PM" Content="11:00 PM" 
                                GroupName="QuickPick"/>
                </WrapPanel>
                
                <!-- Tomorrow Options -->
                <TextBlock Text="Tomorrow" FontWeight="Bold" Margin="0,0,0,5"/>
                <WrapPanel Name="TomorrowPanel">
                    <RadioButton Name="TomorrowMorning" Content="9:00 AM" 
                                GroupName="QuickPick" Margin="0,0,15,0"/>
                    <RadioButton Name="TomorrowAfternoon" Content="2:00 PM" 
                                GroupName="QuickPick" Margin="0,0,15,0"/>
                    <RadioButton Name="TomorrowEvening" Content="8:00 PM" 
                                GroupName="QuickPick"/>
                </WrapPanel>
            </StackPanel>
        </Border>
        
        <!-- Custom Date/Time -->
        <Border Grid.Row="3" BorderBrush="#CCCCCC" BorderThickness="1" 
                Background="White" CornerRadius="5">
            <StackPanel Margin="10">
                <RadioButton Name="CustomOption" Content="Custom Date and Time" 
                            GroupName="QuickPick" FontWeight="Bold" Margin="0,0,0,10"/>
                
                <Calendar Name="Calendar" 
                         HorizontalAlignment="Center"
                         IsEnabled="False"/>
                
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" 
                           Margin="0,10,0,10">
                    <TextBlock Text="Time:" VerticalAlignment="Center" Margin="0,0,10,0"/>
                    <ComboBox Name="HourCombo" Width="80" IsEnabled="False" MaxDropDownHeight="200">
                        <ComboBoxItem>12 AM</ComboBoxItem>
                        <ComboBoxItem>1 AM</ComboBoxItem>
                        <ComboBoxItem>2 AM</ComboBoxItem>
                        <ComboBoxItem>3 AM</ComboBoxItem>
                        <ComboBoxItem>4 AM</ComboBoxItem>
                        <ComboBoxItem>5 AM</ComboBoxItem>
                        <ComboBoxItem>6 AM</ComboBoxItem>
                        <ComboBoxItem>7 AM</ComboBoxItem>
                        <ComboBoxItem>8 AM</ComboBoxItem>
                        <ComboBoxItem>9 AM</ComboBoxItem>
                        <ComboBoxItem>10 AM</ComboBoxItem>
                        <ComboBoxItem>11 AM</ComboBoxItem>
                        <ComboBoxItem>12 PM</ComboBoxItem>
                        <ComboBoxItem>1 PM</ComboBoxItem>
                        <ComboBoxItem>2 PM</ComboBoxItem>
                        <ComboBoxItem>3 PM</ComboBoxItem>
                        <ComboBoxItem>4 PM</ComboBoxItem>
                        <ComboBoxItem>5 PM</ComboBoxItem>
                        <ComboBoxItem>6 PM</ComboBoxItem>
                        <ComboBoxItem>7 PM</ComboBoxItem>
                        <ComboBoxItem>8 PM</ComboBoxItem>
                        <ComboBoxItem>9 PM</ComboBoxItem>
                        <ComboBoxItem>10 PM</ComboBoxItem>
                        <ComboBoxItem>11 PM</ComboBoxItem>
                    </ComboBox>
                </StackPanel>
            </StackPanel>
        </Border>
        
        <!-- Warning Message -->
        <TextBlock Name="WarningText" Grid.Row="4" 
                  Text="" 
                  Foreground="Red" FontWeight="Bold"
                  HorizontalAlignment="Center" Margin="0,10,0,0"
                  Visibility="Collapsed"/>
        
        <!-- Buttons -->
        <StackPanel Grid.Row="5" Orientation="Horizontal" 
                   HorizontalAlignment="Right" Margin="0,10,0,0">
            <Button Name="ScheduleButton" Content="Schedule" 
                   Width="80" Height="25" Margin="0,0,10,0"
                   IsEnabled="False"/>
            <Button Name="CancelButton" Content="Cancel" 
                   Width="80" Height="25"/>
        </StackPanel>
    </Grid>
</Window>
'@
    
    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [Windows.Markup.XamlReader]::Load($reader)
    
    # Get controls
    $tonight8PM = $window.FindName('Tonight8PM')
    $tonight10PM = $window.FindName('Tonight10PM')
    $tonight11PM = $window.FindName('Tonight11PM')
    $tomorrowMorning = $window.FindName('TomorrowMorning')
    $tomorrowAfternoon = $window.FindName('TomorrowAfternoon')
    $tomorrowEvening = $window.FindName('TomorrowEvening')
    $customOption = $window.FindName('CustomOption')
    $calendar = $window.FindName('Calendar')
    $hourCombo = $window.FindName('HourCombo')
    $scheduleButton = $window.FindName('ScheduleButton')
    $cancelButton = $window.FindName('CancelButton')
    $warningText = $window.FindName('WarningText')
    
    # Set calendar constraints - 14 day maximum per requirement
    $calendar.DisplayDateStart = [DateTime]::Today
    $calendar.DisplayDateEnd = [DateTime]::Today.AddDays(14)
    $calendar.SelectedDate = [DateTime]::Today.AddDays(1)
    
    # Disable tonight options if times have passed
    $currentHour = [DateTime]::Now.Hour
    if ($currentHour -ge 20) { $tonight8PM.IsEnabled = $false }
    if ($currentHour -ge 22) { $tonight10PM.IsEnabled = $false }
    if ($currentHour -ge 23) { $tonight11PM.IsEnabled = $false }
    
    # If all tonight options are disabled, add message
    if (-not $tonight8PM.IsEnabled -and -not $tonight10PM.IsEnabled -and -not $tonight11PM.IsEnabled) {
        $tonight8PM.Content = "Too late for tonight"
        $tonight8PM.IsEnabled = $false
        $tonight10PM.Visibility = 'Collapsed'
        $tonight11PM.Visibility = 'Collapsed'
    }
    
    # Selection result
    $script:selectedSchedule = $null
    
    # Handle quick pick changes
    $quickPickHandler = {
        $scheduleButton.IsEnabled = $true
        $calendar.IsEnabled = $false
        $hourCombo.IsEnabled = $false
        $warningText.Visibility = 'Collapsed'
        
        # Check if scheduling within 4 hours
        $selectedTime = $null
        if ($tonight8PM.IsChecked) { 
            $selectedTime = [DateTime]::Today.AddHours(20) 
        }
        elseif ($tonight10PM.IsChecked) { 
            $selectedTime = [DateTime]::Today.AddHours(22) 
        }
        elseif ($tonight11PM.IsChecked) { 
            $selectedTime = [DateTime]::Today.AddHours(23) 
        }
        
        if ($selectedTime) {
            $hoursUntil = ($selectedTime - [DateTime]::Now).TotalHours
            if ($hoursUntil -lt 4 -and $hoursUntil -gt 0) {
                $warningText.Text = "Warning: Scheduling in $([Math]::Round($hoursUntil, 1)) hours!"
                $warningText.Visibility = 'Visible'
            }
        }
    }
    
    # Handle custom option
    $customHandler = {
        if ($customOption.IsChecked) {
            $calendar.IsEnabled = $true
            $hourCombo.IsEnabled = $true
            $scheduleButton.IsEnabled = $true
            $warningText.Visibility = 'Collapsed'
        }
    }
    
    # Add event handlers
    $tonight8PM.Add_Checked($quickPickHandler)
    $tonight10PM.Add_Checked($quickPickHandler)
    $tonight11PM.Add_Checked($quickPickHandler)
    $tomorrowMorning.Add_Checked($quickPickHandler)
    $tomorrowAfternoon.Add_Checked($quickPickHandler)
    $tomorrowEvening.Add_Checked($quickPickHandler)
    $customOption.Add_Checked($customHandler)
    
    # Schedule button click
    $scheduleButton.Add_Click({
        if ($tonight8PM.IsChecked) {
            $script:selectedSchedule = "Tonight - 8 PM"
        }
        elseif ($tonight10PM.IsChecked) {
            $script:selectedSchedule = "Tonight - 10 PM"
        }
        elseif ($tonight11PM.IsChecked) {
            $script:selectedSchedule = "Tonight - 11 PM"
        }
        elseif ($tomorrowMorning.IsChecked) {
            $script:selectedSchedule = "Tomorrow - Morning (9 AM)"
        }
        elseif ($tomorrowAfternoon.IsChecked) {
            $script:selectedSchedule = "Tomorrow - Afternoon (2 PM)"
        }
        elseif ($tomorrowEvening.IsChecked) {
            $script:selectedSchedule = "Tomorrow - Evening (8 PM)"
        }
        elseif ($customOption.IsChecked -and $calendar.SelectedDate) {
            $selectedDate = $calendar.SelectedDate
            $hour = if ($hourCombo.SelectedIndex -ge 0) { $hourCombo.SelectedIndex } else { 20 }
            $scheduledTime = $selectedDate.AddHours($hour)
            
            # Validate minimum 2 hours ahead
            if (($scheduledTime - [DateTime]::Now).TotalHours -lt 2) {
                [System.Windows.MessageBox]::Show(
                    "Please select a time at least 2 hours from now.",
                    "Invalid Time",
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Warning
                )
                return
            }
            
            $script:selectedSchedule = $scheduledTime
        }
        
        $window.DialogResult = $true
        $window.Close()
    })
    
    # Cancel button
    $cancelButton.Add_Click({
        $window.DialogResult = $false
        $window.Close()
    })
    
    # Show dialog
    $result = $window.ShowDialog()
    
    if ($result -and $script:selectedSchedule) {
        return $script:selectedSchedule
    }
    
    return $null
}

# If running standalone, test it
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "Testing Enhanced Calendar Picker..." -ForegroundColor Cyan
    $result = Show-EnhancedCalendarPicker
    if ($result) {
        Write-Host "Selected: $result" -ForegroundColor Green
    } else {
        Write-Host "Cancelled" -ForegroundColor Yellow
    }
}