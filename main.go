package main

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"

	"github.com/charmbracelet/bubbles/textarea"
	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	textarea     textarea.Model
	viewport     viewport.Model
	filename     string
	content      string
	mode         string // "view" or "edit"
	width        int
	height       int
	statusMsg    string
}

func initialModel(filename string) model {
	ta := textarea.New()
	ta.Placeholder = "テキストを入力してください..."
	ta.Focus()

	vp := viewport.New(80, 20)
	vp.Style = lipgloss.NewStyle().
		BorderStyle(lipgloss.RoundedBorder()).
		BorderForeground(lipgloss.Color("62"))

	content := ""
	if filename != "" {
		if data, err := ioutil.ReadFile(filename); err == nil {
			content = string(data)
		}
	}

	ta.SetValue(content)
	vp.SetContent(content)

	return model{
		textarea:  ta,
		viewport:  vp,
		filename:  filename,
		content:   content,
		mode:      "edit",
		statusMsg: fmt.Sprintf("ファイル: %s | モード: 編集", filename),
	}
}

func (m model) Init() tea.Cmd {
	return textarea.Blink
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmds []tea.Cmd
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		m.textarea.SetWidth(msg.Width - 4)
		m.textarea.SetHeight(msg.Height - 6)
		m.viewport.Width = msg.Width - 4
		m.viewport.Height = msg.Height - 6

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "esc":
			return m, tea.Quit

		case "ctrl+s":
			if m.filename != "" {
				content := m.textarea.Value()
				err := ioutil.WriteFile(m.filename, []byte(content), 0644)
				if err != nil {
					m.statusMsg = fmt.Sprintf("保存エラー: %v", err)
				} else {
					m.statusMsg = fmt.Sprintf("保存完了: %s", m.filename)
				}
			} else {
				m.statusMsg = "ファイル名が指定されていません"
			}

		case "ctrl+v":
			if m.mode == "edit" {
				m.mode = "view"
				m.viewport.SetContent(m.textarea.Value())
				m.statusMsg = fmt.Sprintf("ファイル: %s | モード: 表示", m.filename)
			} else {
				m.mode = "edit"
				m.statusMsg = fmt.Sprintf("ファイル: %s | モード: 編集", m.filename)
			}

		default:
			if m.mode == "edit" {
				m.textarea, cmd = m.textarea.Update(msg)
				cmds = append(cmds, cmd)
			} else {
				m.viewport, cmd = m.viewport.Update(msg)
				cmds = append(cmds, cmd)
			}
		}
	}

	return m, tea.Batch(cmds...)
}

func (m model) View() string {
	var content string
	
	if m.mode == "edit" {
		content = m.textarea.View()
	} else {
		content = m.viewport.View()
	}

	statusBar := lipgloss.NewStyle().
		Foreground(lipgloss.Color("240")).
		Background(lipgloss.Color("235")).
		Padding(0, 1).
		Render(m.statusMsg)

	helpText := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Render("Ctrl+S: 保存 | Ctrl+V: 表示/編集切替 | Ctrl+C/Esc: 終了")

	return lipgloss.JoinVertical(
		lipgloss.Left,
		content,
		"",
		statusBar,
		helpText,
	)
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("使用方法: owntexteditor <ファイル名>")
		fmt.Println("例: owntexteditor sample.txt")
		os.Exit(1)
	}

	filename := os.Args[1]
	
	if _, err := os.Stat(filename); os.IsNotExist(err) {
		file, err := os.Create(filename)
		if err != nil {
			log.Fatalf("ファイル作成エラー: %v", err)
		}
		file.Close()
	}

	p := tea.NewProgram(initialModel(filename), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}
