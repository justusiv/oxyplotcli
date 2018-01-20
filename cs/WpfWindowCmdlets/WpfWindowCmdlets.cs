﻿using System;
using System.Collections.Generic;
using System.Collections;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Windows;
using System.Windows.Markup;
using System.Windows.Media;
using System.Reflection;

namespace WpfWindowCmdlets
{
    public class Util
    {
        static public bool IsWindowClosed(Window w)
        {
            var prop = w.GetType().GetProperty("IsDisposed", BindingFlags.NonPublic | BindingFlags.Instance);
            return (bool)prop.GetValue(w);
        }

        static public void OpenWindow(List<Window> result, AutoResetEvent e)
        {
            var window = new Window();
            window.AllowsTransparency = true;
            window.Background = Brushes.Transparent;
            window.WindowStyle = WindowStyle.None;
            window.Width = 0;
            window.Height = 0;
            window.ResizeMode = ResizeMode.NoResize;
            window.ShowInTaskbar = false;

            result.Add(window);

            e.Set();

            window.ShowDialog();
        }
    }

    [Cmdlet("New", "WpfWindow")]
    public class OpenWpfWindow : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = false)]
        public string XamlString { get; set; }

        [Parameter(Position = 1, Mandatory = false)]
        public Hashtable Options { get; set; }

        static private Window _rootWindow;
        static private PowerShell _powerShell;

        private void OpenRootWindow()
        {
            if (_rootWindow != null) {
                if (!Util.IsWindowClosed(_rootWindow)) {
                    return;
                }
            }

            var runspace = RunspaceFactory.CreateRunspace();
            runspace.ApartmentState = ApartmentState.STA;
            runspace.ThreadOptions = PSThreadOptions.UseNewThread;
            runspace.Open();

            _powerShell = PowerShell.Create();
            _powerShell.Runspace = runspace;

            var result = new List<Window>();
            var e = new AutoResetEvent(false);

            _powerShell.AddScript(@"
                param($result, $event)
                [WpfWindowCmdlets.Util]::OpenWindow($result, $event)");
            _powerShell.AddParameter("result", result);
            _powerShell.AddParameter("event", e);

            _powerShell.BeginInvoke();

            e.WaitOne();

            _rootWindow = result[0];
        }

        protected override void EndProcessing()
        {
            Window window = null;

            OpenRootWindow();

            _rootWindow.Dispatcher.Invoke(() => {
                if (XamlString != null) {
                    window = (Window)XamlReader.Parse(XamlString);
                }
                else {
                    window = new Window();
                }

                var type = window.GetType();
                if (Options != null) {
                    foreach (DictionaryEntry entry in Options) {
                        var prop = type.GetProperty((string)entry.Key);
                        prop.SetValue(window, entry.Value);
                    }
                }

                window.Show();
            });


            GetWpfWindowList.WindowList.Add(window);

            WriteObject(window);
        }
    }

    [Cmdlet("Close", "WpfWindow")]
    public class CloseWpfWindow : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public Window Window { get; set; }

        protected override void EndProcessing()
        {
            Window.Dispatcher.InvokeShutdown();
        }
    }

    [Cmdlet("Invoke", "WpfWindowAction")]
    public class InvokeWpfWindowAction : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public Window Window { get; set; }

        [Parameter(Position = 1, Mandatory = true)]
        public ScriptBlock Action { get; set; }

        protected override void EndProcessing()
        {
            Window.Dispatcher.Invoke(() => {
                InvokeCommand.InvokeScript(false, Action, null);
            });
        }
    }

    [Cmdlet("Test", "WpfWindowClosed")]
    public class TestWpfWindowClosed : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public Window Window { get; set; }

        protected override void EndProcessing()
        {
            WriteObject(Util.IsWindowClosed(Window));
        }
    }

    [Cmdlet("Get", "WpfWindowList")]
    public class GetWpfWindowList : PSCmdlet
    {
        static private List<Window> _windowList = new List<Window>();

        static public List<Window> WindowList { get { return _windowList; } }

        protected override void EndProcessing()
        {
            _windowList.RemoveAll((w) => { return Util.IsWindowClosed(w); });

            foreach (var w in _windowList) {
                WriteObject(w);
            }
        }
    }
}