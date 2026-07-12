package backend.languages;

class ZhHK 
{
    public static var languageName:String = "Chinese (Hong Kong)";
    public static var languageCode:String = "zh-HK";
    
    public static var translations:Map<String, String> = [
        "update_available_title" => "更新可用！",
        "version_comparison" => "当前版本: {1} => 新版本: {2}",
        "loading_changelog" => "正在加载更新日志...",
        "update_controls" => "按ENTER更新到最新版本\n如果你使用的是正确的引擎版本，请按ESCAPE\n你可以在选项菜单中禁用此警告",
        "changelog_title" => "更新内容:\n{1}",
        "changelog_error" => "加载更新日志时出错: {1}",

        // Gameplay
        "score_text" => "分數: {1} | 失誤: {2} | 評級: {3}",
        "score_text_instakill" => "分數: {1} | 評級: {2}",
        "botplay" => "自動遊戲",

        // Ratings
        "rating_you_suck" => "你太廢了！",
        "rating_shit" => "糟糕",
        "rating_bad" => "差",
        "rating_bruh" => "額",
        "rating_meh" => "一般",
        "rating_nice" => "不錯",
        "rating_good" => "好",
        "rating_great" => "很棒",
        "rating_sick" => "超棒！",
        "rating_flawless" => "史詩！！",
        "rating_perfect" => "完美！！！",

        // Dialogues
        "dialogue_skip" => "按返回鍵跳過",

        // Pause Menu
        "practice_mode" => "練習模式",
        "charting_mode" => "製譜模式",
        "blueballed" => "失敗次數: {1}",

        // Story Mode
        "week_score" => "週分數: {1}",
        "storyname_tutorial" => "教學",
        "storyname_week1" => "親愛的爸爸",
        "storyname_week2" => "恐怖月",
        "storyname_week3" => "皮科",
        "storyname_week4" => "媽媽必須殺戮",
        "storyname_week5" => "紅雪",
        "storyname_week6" => "仇恨模擬器 ft. 喵靈",
        "storyname_week7" => "坦克手",
        "storyname_weekend1" => "到期債務",

        // Freeplay
        "personal_best" => "個人最佳: {1} ({2}%)",
        "freeplay_tip" => "按空格鍵試聽歌曲 / 按CTRL打開遊戲修改器選單 / 按RESET重置你的分數和準確度。",
        "musicplayer_playing" => "正在播放: {1}",
        "musicplayer_paused" => "正在播放: {1} (已暫停)",
        "musicplayer_tip" => "按空格鍵暫停 / 按ESC退出 / 按R重置歌曲",

        // Mods Menu
        "no_mods_installed" => "未安裝模組\n按返回鍵退出或安裝模組",
        "no_mods_found" => "未找到模組。",
        "mod_restart" => "* 移動或切換此模組將重啟遊戲。",

        // Credits
        "description_shadow_mario" => "Psych Engine 團隊",

        // Reset Score/Achievement
        "reset_score" => "重置分數",
        "reset_achievement" => "重置成就:",
        "yes" => "是",
        "no" => "否",

        // Achievements
        "achievement_friday_night_play" => "週五夜放克",
        "description_friday_night_play" => "在週五...夜晚遊戲。",
        "achievement_week1_nomiss" => "她也叫我爸爸",
        "description_week1_nomiss" => "在困難模式下無失誤通關第1週。",
        "achievement_week2_nomiss" => "不再惡作劇",
        "description_week2_nomiss" => "在困難模式下無失誤通關第2週。",
        "achievement_week3_nomiss" => "叫我殺手",
        "description_week3_nomiss" => "在困難模式下無失誤通關第3週。",
        "achievement_week4_nomiss" => "女性殺手",
        "description_week4_nomiss" => "在困難模式下無失誤通關第4週。",
        "achievement_week5_nomiss" => "無失誤聖誕節",
        "description_week5_nomiss" => "在困難模式下無失誤通關第5週。",
        "achievement_week6_nomiss" => "高分！！",
        "description_week6_nomiss" => "在困難模式下無失誤通關第6週。",
        "achievement_week7_nomiss" => "該死的！",
        "description_week7_nomiss" => "在困難模式下無失誤通關第7週。",
        "achievement_ur_bad" => "真是個放克災難！",
        "description_ur_bad" => "以低於20%的評級完成一首歌曲",
        "achievement_ur_good" => "完美主義者",
        "description_ur_good" => "以100%的評級完成一首歌曲",
        "achievement_roadkill_enthusiast" => "路殺愛好者",
        "description_roadkill_enthusiast" => "觀看手下死亡50次。",
        "achievement_oversinging" => "過度演唱...？",
        "description_oversinging" => "連續演唱10秒不回到待機狀態。",
        "achievement_hype" => "過度活躍",
        "description_hype" => "完成一首歌曲不回到待機狀態。",
        "achievement_two_keys" => "只有我們兩個",
        "description_two_keys" => "只按兩個鍵完成一首歌曲。",
        "achievement_toastie" => "烤麵包機玩家",
        "description_toastie" => "你試過在烤麵包機上運行遊戲嗎？",
        "achievement_debugger" => "調試者",
        "description_debugger" => "在譜面編輯器中擊敗\"測試\"關卡。",
        "achievement_pessy_easter_egg" => "引擎女孩夥伴",
        "description_pessy_easter_egg" => "嘿嘿，你找到我了~！",

        // Note Colors Menu
        "note_colors_tip" => "按RESET重置所選音符部分。",
        "note_colors_hold_tip" => "按住 {1} + 按RESET鍵完全重置所選音符。",
        "note_colors_shift" => "Shift",
        "note_colors_lb" => "左肩按鈕",

        // Adjust Delay and Combo Menu
        "delay_beat_hit" => "節拍命中！",
        "delay_current_offset" => "當前偏移: {1} 毫秒",
        "combo_rating_offset" => "評級偏移:",
        "combo_numbers_offset" => "數字偏移:",
        "combo_offset" => "連擊偏移",
        "note_delay" => "音符延遲",
        "switch_on_accept" => "(按確認鍵切換)",
        "switch_on_start" => "(按開始鍵切換)",

        // Graphics Settings
        "description_low_quality" => "如果選中，禁用一些背景細節，\n減少載入時間並提高性能。",
        "description_anti-aliasing" => "如果未選中，禁用抗鋸齒，提高性能\n但視覺效果會更粗糙。",
        "description_shaders" => "如果未選中，禁用著色器。\n它用於一些視覺效果，對較弱的PC來說CPU密集。",
        "description_gpu_caching" => "如果選中，允許GPU用於緩存紋理，減少RAM使用。\n如果你的顯卡很差，不要打開這個。",
        "description_framerate" => "很好理解的，不是嗎？",
        "description_fps_rework" => "如果啟用，當當前FPS低於幀率限制時，\n遊戲將防止“卡頓”或“平滑”。",

        // Visuals Settings
        "description_note_skins" => "選擇你喜歡的音符皮膚。",
        "description_note_splashes" => "選擇你喜歡的音符飛濺變體或關閉它。",
        "description_note_splash_opacity" => "音符飛濺應該有多透明。",
        "description_hide_hud" => "如果選中，隱藏大部分HUD元素。",
        "description_time_bar" => "時間條應該顯示什麼？",
        "description_flashing_lights" => "如果你對閃爍燈光敏感，請取消選中！",
        "description_camera_zooms" => "如果未選中，相機不會在節拍命中時縮放。",
        "description_score_text_grow_on_hit" => "如果未選中，禁用分數文字在\n每次擊中音符時增長。",
        "description_abbreviate_score" => "如果選中，分數將被縮寫（例如 10.00K, 1.00M）。",
        "description_debug_data" => "顯示譜面資訊如滾動速度、BPM、生命值；還有步驟、節拍等。\n如果你在譜面模式下，後者將可用。",
        "description_health_bar_opacity" => "生命條和圖示應該有多透明。",
        "description_fps_counter" => "如果未選中，隱藏FPS計數器。",
        "description_vsync" => "如果選中，啟用垂直同步，修復屏幕撕裂，\n但FPS將被限制為顯示器的刷新率。\n（需要重啟遊戲以應用）",
        "description_pause_music" => "你喜歡暫停螢幕播放什麼歌曲？",
        "description_check_for_updates" => "在發布版本中，打開此選項在啟動遊戲時檢查更新。",
        "description_discord_rich_presence" => "取消選中以防止意外洩露，它將在Discord的\"正在遊戲\"框中隱藏應用程式",
        "description_combo_stacking" => "如果未選中，評級和連擊不會堆疊，節省系統記憶體並使其更易閱讀",
        "description_show_current_state" => "如果選中，FPS計數器將顯示當前狀態。",
        "description_combo_and_rating_in_camgame" => "如果選中，連擊和評級將在camGame層而不是camHUD中渲染。",

        // Gameplay Settings
        "description_downscroll" => "如果選中，音符向下而不是向上，很簡單。",
        "description_middlescroll" => "如果選中，你的音符居中。",
        "description_opponent_notes" => "如果未選中，對手音符被隱藏。",
        "description_ghost_tapping" => "如果選中，當沒有可擊中的音符時\n按鍵不會失誤。",
        "description_pop_up_score" => "如果選中，擊中音符時會顯示你獲得的分數。",
        "description_auto_pause" => "如果選中，當螢幕失去焦點時遊戲自動暫停。",
        "description_disable_reset_button" => "如果選中，按重置不會做任何事。",
        "description_hitsound_volume" => "有趣的音符在你擊中時發出\"滴答\"聲。",
        "description_rating_offset" => "改變擊中\"超棒！\"需要多晚/多早\n更高的值意味著你需要擊中得更晚。",
        "description_flawless_hit_window" => "改變你擊中史詩！的時間量（毫秒）。",
        "description_sick_hit_window" => "改變你擊中\"超棒！\"的時間量（毫秒）。",
        "description_good_hit_window" => "改變你擊中\"好\"的時間量（毫秒）。",
        "description_bad_hit_window" => "改變你擊中\"差\"的時間量（毫秒）。",
        "description_safe_frames" => "改變你擊中音符早或晚的幀數。",
        "description_sustains_as_one_note" => "如果選中，如果你失誤，長音符不能被按下，\n並計為單次命中/失誤。\n如果你喜歡舊輸入系統，請取消選中。",
        "description_judgement_counter" => "如果選中，在遊戲中顯示判定計數器。",
        "description_show_end_countdown" => "如果選中，在歌曲結束時顯示倒數。",
        "description_end_countdown_seconds" => "歌曲結束時倒數應該持續多少秒。\n(10 - 30)",

        // Loading Screen
        "now_loading" => "載入中{1}",

        // Difficulties
        "difficulty_easy" => "簡單",
        "difficulty_normal" => "普通",
        "difficulty_hard" => "困難",

        // Debug and Time
        "debug_speed" => "速度",
        "debug_bpm" => "BPM",
        "debug_health" => "生命值",

        // PlayState - Days of the week
        "day_sunday" => "星期日",
        "day_monday" => "星期一",
        "day_tuesday" => "星期二",
        "day_wednesday" => "星期三",
        "day_thursday" => "星期四",
        "day_friday" => "星期五",
        "day_saturday" => "星期六",

        // PlayState - Months
        "month_january" => "一月",
        "month_february" => "二月",
        "month_march" => "三月",
        "month_april" => "四月",
        "month_may" => "五月",
        "month_june" => "六月",
        "month_july" => "七月",
        "month_august" => "八月",
        "month_september" => "九月",
        "month_october" => "十月",
        "month_november" => "十一月",
        "month_december" => "十二月",

        // Rating FC (Full Combo variations)
        "clear" => "通關",
        "sdcb" => "SDCB",
        "fc" => "FC",
        "gfc" => "GFC",
        "sfc" => "SFC",
        "rating_fc" => "FC",
        "rating_gfc" => "GFC",
        "rating_sfc" => "SFC",
        "rating_bfc" => "BFC", 
        "rating_efc" => "EFC",
        "rating_smc" => "SMC",
        "rating_lmc" => "LMC", 
        "rating_mmc" => "MMC",
        "rating_hmc" => "HMC",

        "reset_score_confirm" => "你確定要重置這首歌的分數和準確度嗎？",

        "time_hours" => "小時",

        // Judgment counters  
        "judgement_flawlesss" => "史詩   ",
        "judgement_sicks" => "超棒   ", 
        "judgement_goods" => "好     ",
        "judgement_bads" => "差     ",
        "judgement_shits" => "糟糕   ",
        "judgement_misses" => "失誤   ",
        "judgement_combo" => "連擊   ",
        "judgement_max_combo" => "最大連擊",

        // ============== IMAGE TRANSLATIONS ==============
        
        // Difficulties (mismo path que zh-CN por simplicidad)
        "images/menudifficulties/easy" => "images/zh-HK/menudifficulties/easy",
        "images/menudifficulties/normal" => "images/zh-HK/menudifficulties/normal", 
        "images/menudifficulties/hard" => "images/zh-HK/menudifficulties/hard",

        // Game UI (mismo path que zh-CN por simplicidad)
        "images/menu_tracks" => "images/zh-HK/Menu_Tracks",

        "editorplaystate_section" => "部分: {1}",
        "editorplaystate_tip" => "按ESC返回到图表编辑器",
        "editorplaystate_time" => "时间: {1} / {2}",
        "editorplaystate_section_current" => "部分: {1}",
        "editorplaystate_beat" => "节拍: {1}",
        "editorplaystate_step" => "步骤: {1}",
        "editorplaystate_score" => "命中: {1} | 失误: {2}",
        
        // Language example text
        "language_example_text" => "這是中文（香港）語言的示例文本"
    ];
}