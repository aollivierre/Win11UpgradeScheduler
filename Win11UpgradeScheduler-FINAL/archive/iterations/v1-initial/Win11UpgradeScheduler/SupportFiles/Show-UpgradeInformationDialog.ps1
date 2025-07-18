Function Show-UpgradeInformationDialog {
    <#
    .SYNOPSIS
        Shows a comprehensive Windows 11 upgrade information dialog before scheduling
    .DESCRIPTION
        Creates a professional information dialog that displays upgrade requirements,
        process details, and important notices before allowing users to schedule
    .PARAMETER OrganizationName
        Name of the organization (default: "Your Organization")
    .PARAMETER DeadlineDays
        Number of days before automatic upgrade (default: 14)
    .OUTPUTS
        Boolean - True if user proceeds to scheduling, False if cancelled
    .EXAMPLE
        $proceed = Show-UpgradeInformationDialog -OrganizationName "ABC Corporation" -DeadlineDays 14
    #>
    [CmdletBinding()]
    [OutputType([Boolean])]
    Param(
        [Parameter(Mandatory=$false)]
        [String]$OrganizationName = "Your Organization",
        
        [Parameter(Mandatory=$false)]
        [Int]$DeadlineDays = 14
    )
    
    try {
        Write-Log -Message "Loading Windows 11 upgrade information dialog..." -Source 'Show-UpgradeInformationDialog'
        
        # Load required assemblies
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        
        # XAML for the information dialog
        [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Windows 11 Upgrade Required" 
        Height="580" 
        Width="600" 
        WindowStartupLocation="CenterScreen" 
        ResizeMode="NoResize"
        Topmost="True"
        Background="#F9F9F9">
    <Grid Margin="0">
        <Grid.RowDefinitions>
            <RowDefinition Height="60"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="60"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#0078D4" CornerRadius="0">
            <StackPanel Orientation="Vertical" VerticalAlignment="Center" Margin="20,10">
                <TextBlock Text="Windows 11 Upgrade Required" 
                          FontFamily="Segoe UI" 
                          FontSize="18" 
                          FontWeight="SemiBold"
                          Foreground="White"/>
                <TextBlock Text="Version 24H2 Update" 
                          FontFamily="Segoe UI" 
                          FontSize="12" 
                          Foreground="#E1E1E1"
                          Margin="0,2,0,0"/>
            </StackPanel>
        </Border>
        
        <!-- Content -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Margin="20,15,20,15">
            <StackPanel>
                <!-- Status Section -->
                <TextBlock Text="Status" 
                          FontFamily="Segoe UI" 
                          FontSize="14" 
                          FontWeight="SemiBold"
                          Foreground="#323130"
                          Margin="0,0,0,8"/>
                
                <TextBlock Text="Ready to schedule Windows 11 upgrade" 
                          FontFamily="Segoe UI" 
                          FontSize="12"
                          Foreground="#605E5C"
                          Margin="0,0,0,20"/>
                
                <!-- Information Section -->
                <TextBlock Text="Information" 
                          FontFamily="Segoe UI" 
                          FontSize="14" 
                          FontWeight="SemiBold"
                          Foreground="#323130"
                          Margin="0,0,0,8"/>
                
                <Border Background="#E3F2FD" 
                        BorderBrush="#2196F3" 
                        BorderThickness="1" 
                        CornerRadius="4" 
                        Padding="12" 
                        Margin="0,0,0,15">
                    <TextBlock Text="Your device needs this critical security update" 
                              FontFamily="Segoe UI" 
                              FontSize="12"
                              FontWeight="Medium"
                              Foreground="#1565C0"/>
                </Border>
                
                <!-- Process Details -->
                <TextBlock Text="This automated upgrade:" 
                          FontFamily="Segoe UI" 
                          FontSize="12" 
                          FontWeight="SemiBold"
                          Foreground="#323130"
                          Margin="0,0,0,8"/>
                
                <StackPanel Margin="15,0,0,15">
                    <StackPanel Orientation="Horizontal" Margin="0,2">
                        <Ellipse Width="6" Height="6" Fill="#323130" VerticalAlignment="Center" Margin="0,0,8,0"/>
                        <TextBlock Text="Takes approximately 2 hours to complete" 
                                  FontFamily="Segoe UI" 
                                  FontSize="12"
                                  Foreground="#323130"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,2">
                        <Ellipse Width="6" Height="6" Fill="#323130" VerticalAlignment="Center" Margin="0,0,8,0"/>
                        <TextBlock Text="Will restart your device multiple times" 
                                  FontFamily="Segoe UI" 
                                  FontSize="12"
                                  Foreground="#323130"/>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,2">
                        <Ellipse Width="6" Height="6" Fill="#323130" VerticalAlignment="Center" Margin="0,0,8,0"/>
                        <TextBlock Text="Runs without requiring your interaction" 
                                  FontFamily="Segoe UI" 
                                  FontSize="12"
                                  Foreground="#323130"/>
                    </StackPanel>
                </StackPanel>
                
                <!-- Requirements Section -->
                <Border Background="#F3F4F6" 
                        BorderBrush="#D1D5DB" 
                        BorderThickness="1" 
                        CornerRadius="4" 
                        Padding="12" 
                        Margin="0,0,0,15">
                    <StackPanel>
                        <TextBlock Text="Requirements:" 
                                  FontFamily="Segoe UI" 
                                  FontSize="12" 
                                  FontWeight="SemiBold"
                                  Foreground="#374151"
                                  Margin="0,0,0,8"/>
                        
                        <StackPanel Margin="8,0,0,0">
                            <StackPanel Orientation="Horizontal" Margin="0,2">
                                <Ellipse Width="5" Height="5" Fill="#374151" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                <TextBlock Text="Connect to internet (Wi-Fi or ethernet)" 
                                          FontFamily="Segoe UI" 
                                          FontSize="11"
                                          Foreground="#374151"/>
                            </StackPanel>
                            <StackPanel Orientation="Horizontal" Margin="0,2">
                                <Ellipse Width="5" Height="5" Fill="#374151" VerticalAlignment="Center" Margin="0,0,8,0"/>
                                <TextBlock Text="Connect to power source" 
                                          FontFamily="Segoe UI" 
                                          FontSize="11"
                                          Foreground="#374151"/>
                            </StackPanel>
                        </StackPanel>
                    </StackPanel>
                </Border>
                
                <!-- Important Notice -->
                <Border Background="#FFF3CD" 
                        BorderBrush="#FFEAA7" 
                        BorderThickness="1" 
                        CornerRadius="4" 
                        Padding="12" 
                        Margin="0,0,0,15">
                    <StackPanel>
                        <TextBlock Name="DeadlineNotice"
                                  Text="Important: You have 14 days to select your preferred time. After this period, the upgrade will be applied automatically during non-business hours." 
                                  FontFamily="Segoe UI" 
                                  FontSize="11"
                                  Foreground="#856404"
                                  TextWrapping="Wrap"/>
                    </StackPanel>
                </Border>
                
                <!-- Support Information -->
                <TextBlock Text="Need help? Contact IT Support" 
                          FontFamily="Segoe UI" 
                          FontSize="11"
                          Foreground="#6C757D"
                          HorizontalAlignment="Center"
                          Margin="0,10,0,0"/>
            </StackPanel>
        </ScrollViewer>
        
        <!-- Footer Buttons -->
        <Border Grid.Row="2" Background="#F1F1F1" BorderBrush="#E0E0E0" BorderThickness="0,1,0,0">
            <StackPanel Orientation="Horizontal" 
                       HorizontalAlignment="Center" 
                       VerticalAlignment="Center"
                       Margin="20,15">
                
                <Button Name="UpgradeNowButton" 
                        Content="Upgrade Now" 
                        Width="120" 
                        Height="36"
                        Margin="0,0,15,0"
                        FontFamily="Segoe UI"
                        FontSize="12"
                        Background="#D32F2F"
                        BorderBrush="#C62828"
                        Foreground="White"
                        ToolTip="Start the upgrade immediately"/>
                
                <Button Name="ScheduleButton" 
                        Content="Schedule" 
                        Width="120" 
                        Height="36"
                        Margin="0,0,15,0"
                        FontFamily="Segoe UI"
                        FontSize="12"
                        Background="#0078D4"
                        BorderBrush="#106EBE"
                        Foreground="White"
                        ToolTip="Choose when to perform the upgrade"/>
                
                <Button Name="RemindLaterButton" 
                        Content="Remind Me Later" 
                        Width="120" 
                        Height="36"
                        FontFamily="Segoe UI"
                        FontSize="12"
                        Background="#6C757D"
                        BorderBrush="#5A6268"
                        Foreground="White"
                        ToolTip="Postpone this decision"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
"@
        
        # Create the window
        $reader = New-Object System.Xml.XmlNodeReader $xaml
        $window = [Windows.Markup.XamlReader]::Load($reader)
        
        # Get controls
        $deadlineNotice = $window.FindName('DeadlineNotice')
        $upgradeNowButton = $window.FindName('UpgradeNowButton')
        $scheduleButton = $window.FindName('ScheduleButton')
        $remindLaterButton = $window.FindName('RemindLaterButton')
        
        # Update deadline notice with actual days
        $deadlineNotice.Text = "Important: You have $DeadlineDays days to select your preferred time. After this period, the upgrade will be applied automatically during non-business hours."
        
        # Variables to track user choice
        $script:userChoice = $null
        
        # Button event handlers
        $upgradeNowButton.Add_Click({
            Write-Log -Message "User selected 'Upgrade Now'" -Source 'Show-UpgradeInformationDialog'
            $script:userChoice = 'UpgradeNow'
            $window.DialogResult = $true
            $window.Close()
        })
        
        $scheduleButton.Add_Click({
            Write-Log -Message "User selected 'Schedule'" -Source 'Show-UpgradeInformationDialog'
            $script:userChoice = 'Schedule'
            $window.DialogResult = $true
            $window.Close()
        })
        
        $remindLaterButton.Add_Click({
            Write-Log -Message "User selected 'Remind Me Later'" -Source 'Show-UpgradeInformationDialog'
            $script:userChoice = 'RemindLater'
            $window.DialogResult = $false
            $window.Close()
        })
        
        # Handle window closing
        $window.Add_Closing({
            if ($script:userChoice -eq $null) {
                Write-Log -Message "User closed information dialog without selection" -Source 'Show-UpgradeInformationDialog'
                $script:userChoice = 'Cancel'
            }
        })
        
        Write-Log -Message "Displaying Windows 11 upgrade information dialog" -Source 'Show-UpgradeInformationDialog'
        
        # Show the dialog
        $result = $window.ShowDialog()
        
        # Return the user's choice
        Write-Log -Message "User choice: $($script:userChoice)" -Source 'Show-UpgradeInformationDialog'
        return $script:userChoice
        
    } catch {
        Write-Log -Message "Error in upgrade information dialog: $($_.Exception.Message)" -Severity 3 -Source 'Show-UpgradeInformationDialog'
        return 'Cancel'
    }
}