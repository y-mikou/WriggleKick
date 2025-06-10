package main

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"
	"unicode"

	"github.com/charmbracelet/bubbles/v2/textarea"
	"github.com/charmbracelet/bubbles/v2/textinput"
	"github.com/charmbracelet/bubbles/v2/viewport"
	tea "github.com/charmbracelet/bubbletea/v2"
	"github.com/charmbracelet/lipgloss/v2"
)

type IMEState struct {
	isComposing     bool
	compositionText []rune
}

type IMETextarea struct {
	textarea.Model
	imeState IMEState
}

func NewIMETextarea() IMETextarea {
	return IMETextarea{
		Model:    textarea.New(),
		imeState: IMEState{},
	}
}

func (m *IMETextarea) isIMEComposition(msg tea.KeyMsg) bool {
	for _, r := range msg.Runes {
		if (r >= 0x3040 && r <= 0x309F) ||
			(r >= 0x30A0 && r <= 0x30FF) ||
			(r >= 0x4E00 && r <= 0x9FAF) ||
			unicode.In(r, unicode.Hiragana, unicode.Katakana, unicode.Han) {
			return true
		}
	}
	return false
}

func (m *IMETextarea) UpdateWithIME(msg tea.Msg) (IMETextarea, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.isIMEComposition(msg) && len(msg.Runes) > 0 {
			m.imeState.isComposing = true
			m.imeState.compositionText = msg.Runes
			return *m, nil
		} else if m.imeState.isComposing {
			if msg.String() == "enter" || msg.String() == " " {
				if len(m.imeState.compositionText) > 0 {
					compositionStr := string(m.imeState.compositionText)
					m.Model.InsertString(compositionStr)
				}
				m.imeState.isComposing = false
				m.imeState.compositionText = nil
				return *m, nil
			} else if msg.String() == "esc" {
				m.imeState.isComposing = false
				m.imeState.compositionText = nil
				return *m, nil
			}
		}
	}

	model, cmd := m.Model.Update(msg)
	m.Model = model
	return *m, cmd
}

func (m IMETextarea) ViewWithIME() string {
	if !m.imeState.isComposing || len(m.imeState.compositionText) == 0 {
		return m.Model.View()
	}

	currentText := m.Model.Value()
	lines := strings.Split(currentText, "\n")

	cursorRow := m.Model.Line()
	lineInfo := m.Model.LineInfo()
	cursorCol := lineInfo.ColumnOffset
	if cursorRow >= len(lines) {
		cursorRow = len(lines) - 1
	}
	if cursorRow < 0 {
		cursorRow = 0
	}

	if len(lines) == 0 {
		lines = []string{""}
	}

	currentLine := lines[cursorRow]
	if cursorCol > len([]rune(currentLine)) {
		cursorCol = len([]rune(currentLine))
	}

	lineRunes := []rune(currentLine)
	compositionStr := string(m.imeState.compositionText)

	newLineRunes := make([]rune, 0, len(lineRunes)+len(m.imeState.compositionText))
	newLineRunes = append(newLineRunes, lineRunes[:cursorCol]...)
	newLineRunes = append(newLineRunes, []rune(compositionStr)...)
	newLineRunes = append(newLineRunes, lineRunes[cursorCol:]...)

	lines[cursorRow] = string(newLineRunes)
	modifiedText := strings.Join(lines, "\n")

	tempModel := m.Model
	originalValue := tempModel.Value()
	tempModel.SetValue(modifiedText)

	result := tempModel.View()
	tempModel.SetValue(originalValue)

	return result
}

type model struct {
	textarea     IMETextarea
	viewport     viewport.Model
	textinput    textinput.Model
	filename     string
	content      string
	mode         string // "view", "edit", or "save_as"
	width        int
	height       int
	statusMsg    string
	isTemp       bool
	tempFilename string
}

func initialModel(filename string, isTemp bool, tempFilename string) model {
	ta := NewIMETextarea()
	ta.Placeholder = "テキストを入力してください..."
	ta.Focus()

	vp := viewport.New(viewport.WithWidth(80), viewport.WithHeight(20))

	ti := textinput.New()
	ti.Placeholder = "保存するファイル名を入力してください..."
	ti.CharLimit = 256
	ti.SetWidth(50)

	content := ""
	if filename != "" {
		if data, err := os.ReadFile(filename); err == nil {
			content = string(data)
		}
	}

	ta.SetValue(content)
	vp.SetContent(content)

	displayName := filename
	if isTemp {
		displayName = "新規ファイル (一時)"
	}

	return model{
		textarea:     ta,
		viewport:     vp,
		textinput:    ti,
		filename:     filename,
		content:      content,
		mode:         "edit",
		statusMsg:    fmt.Sprintf("ファイル: %s | モード: 編集", displayName),
		isTemp:       isTemp,
		tempFilename: tempFilename,
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
		m.viewport.SetWidth(msg.Width - 4)
		m.viewport.SetHeight(msg.Height - 6)
		m.textinput.SetWidth(msg.Width - 10)

	case tea.KeyMsg:
		if m.mode == "save_as" {
			switch msg.String() {
			case "ctrl+c", "esc":
				m.mode = "edit"
				m.statusMsg = "保存をキャンセルしました"
			case "enter":
				newFilename := m.textinput.Value()
				if newFilename != "" {
					content := m.textarea.Value()
					err := os.WriteFile(newFilename, []byte(content), 0644)
					if err != nil {
						m.statusMsg = fmt.Sprintf("保存エラー: %v", err)
					} else {
						m.filename = newFilename
						m.isTemp = false
						m.statusMsg = fmt.Sprintf("保存完了: %s", newFilename)
					}
					m.mode = "edit"
					m.textinput.SetValue("")
				} else {
					m.statusMsg = "ファイル名を入力してください"
				}
			default:
				m.textinput, cmd = m.textinput.Update(msg)
				cmds = append(cmds, cmd)
			}
		} else {
			switch msg.String() {
			case "ctrl+c", "esc":
				return m, tea.Quit

			case "ctrl+s":
				if m.isTemp {
					m.mode = "save_as"
					m.textinput.Focus()
					m.statusMsg = "保存するファイル名を入力してください (Enter: 保存, Esc: キャンセル)"
				} else if m.filename != "" {
					content := m.textarea.Value()
					err := os.WriteFile(m.filename, []byte(content), 0644)
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
					displayName := m.filename
					if m.isTemp {
						displayName = "新規ファイル (一時)"
					}
					m.statusMsg = fmt.Sprintf("ファイル: %s | モード: 表示", displayName)
				} else {
					m.mode = "edit"
					displayName := m.filename
					if m.isTemp {
						displayName = "新規ファイル (一時)"
					}
					m.statusMsg = fmt.Sprintf("ファイル: %s | モード: 編集", displayName)
				}

			default:
				if m.mode == "edit" {
					m.textarea, cmd = m.textarea.UpdateWithIME(msg)
					cmds = append(cmds, cmd)
				} else {
					m.viewport, cmd = m.viewport.Update(msg)
					cmds = append(cmds, cmd)
				}
			}
		}
	}

	return m, tea.Batch(cmds...)
}

func (m model) View() string {
	var content string

	if m.mode == "save_as" {
		content = lipgloss.JoinVertical(
			lipgloss.Left,
			"ファイル名を入力してください:",
			"",
			m.textinput.View(),
		)
	} else if m.mode == "edit" {
		content = m.textarea.ViewWithIME()
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
	var filename string
	var isTemp bool
	var tempFilename string

	if len(os.Args) < 2 {
		timestamp := time.Now().Format("20060102_150405")
		tempFilename = fmt.Sprintf("temp_%s.txt", timestamp)
		filename = tempFilename
		isTemp = true

		file, err := os.Create(filename)
		if err != nil {
			log.Fatalf("一時ファイル作成エラー: %v", err)
		}
		file.Close()

		fmt.Printf("一時ファイルを作成しました: %s\n", filename)
	} else {
		filename = os.Args[1]
		isTemp = false

		if _, err := os.Stat(filename); os.IsNotExist(err) {
			file, err := os.Create(filename)
			if err != nil {
				log.Fatalf("ファイル作成エラー: %v", err)
			}
			file.Close()
		}
	}

	p := tea.NewProgram(initialModel(filename, isTemp, tempFilename), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}

	if isTemp && tempFilename != "" {
		if _, err := os.Stat(tempFilename); err == nil {
			os.Remove(tempFilename)
			fmt.Printf("一時ファイルを削除しました: %s\n", tempFilename)
		}
	}
}
