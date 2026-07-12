package backend.languages;

class ZhCN 
{
    public static var languageName:String = "Chinese (Mainland)";
    public static var languageCode:String = "zh-CN";
    
    public static var translations:Map<String, String> = [
        "update_available_title" => "更新可用！",
        "version_comparison" => "当前版本: {1} => 新版本: {2}",
        "loading_changelog" => "正在加载更新日志...",
        "update_controls" => "按ENTER更新到最新版本\n如果你使用的是正确的引擎版本，请按ESCAPE\n你可以在选项菜单中禁用此警告",
        "changelog_title" => "更新内容:\n{1}",
        "changelog_error" => "加载更新日志时出错: {1}",

        // Gameplay
        "score_text" => "分数: {1} | 失误: {2} | 评级: {3}",
        "score_text_instakill" => "分数: {1} | 评级: {2}",
        "botplay" => "自动游戏",

        // Ratings
        "rating_you_suck" => "你太菜了！",
        "rating_shit" => "糟糕",
        "rating_bad" => "差",
        "rating_bruh" => "额",
        "rating_meh" => "一般",
        "rating_nice" => "不错",
        "rating_good" => "好",
        "rating_great" => "很棒",
        "rating_sick" => "超棒！",
        "rating_flawless" => "史诗！！",
        "rating_perfect" => "完美！！！",

        // Dialogues
        "dialogue_skip" => "按返回键跳过",

        "practice_mode" => "练习模式",
        "charting_mode" => "制谱模式",
        "blueballed" => "失败次数: {1}",

        // Story Mode
        "week_score" => "周分数: {1}",
        "storyname_tutorial" => "教程",
        "storyname_week1" => "亲爱的爸爸",
        "storyname_week2" => "恐怖月",
        "storyname_week3" => "皮科",
        "storyname_week4" => "妈妈必须杀戮",
        "storyname_week5" => "红雪",
        "storyname_week6" => "仇恨模拟器 ft. 喵灵",
        "storyname_week7" => "坦克手",
        "storyname_weekend1" => "到期债务",

        // Freeplay
        "personal_best" => "个人最佳: {1} ({2}%)",
        "freeplay_tip" => "按空格键试听歌曲 / 按CTRL打开游戏修改器菜单 / 按RESET重置你的分数和准确度。",
        "musicplayer_playing" => "正在播放: {1}",
        "musicplayer_paused" => "正在播放: {1} (已暂停)",
        "musicplayer_tip" => "按空格键暂停 / 按ESC退出 / 按R重置歌曲",

        // Mods Menu
        "no_mods_installed" => "未安装模组\n按返回键退出或安装模组",
        "no_mods_found" => "未找到模组。",
        "mod_restart" => "* 移动或切换此模组将重启游戏。",

        // Credits
        "description_shadow_mario" => "Psych Engine 团队",

        // Reset Score/Achievement
        "reset_score" => "重置分数",
        "reset_achievement" => "重置成就:",
        "yes" => "是",
        "no" => "否",

        // Achievements
        "achievement_friday_night_play" => "周五夜放克",
        "description_friday_night_play" => "在周五...夜晚游戏。",
        "achievement_week1_nomiss" => "她也叫我爸爸",
        "description_week1_nomiss" => "在困难模式下无失误通关第1周。",
        "achievement_week2_nomiss" => "不再恶作剧",
        "description_week2_nomiss" => "在困难模式下无失误通关第2周。",
        "achievement_week3_nomiss" => "叫我杀手",
        "description_week3_nomiss" => "在困难模式下无失误通关第3周。",
        "achievement_week4_nomiss" => "女性杀手",
        "description_week4_nomiss" => "在困难模式下无失误通关第4周。",
        "achievement_week5_nomiss" => "无失误圣诞节",
        "description_week5_nomiss" => "在困难模式下无失误通关第5周。",
        "achievement_week6_nomiss" => "高分！！",
        "description_week6_nomiss" => "在困难模式下无失误通关第6周。",
        "achievement_week7_nomiss" => "该死的！",
        "description_week7_nomiss" => "在困难模式下无失误通关第7周。",
        "achievement_ur_bad" => "真是个放克灾难！",
        "description_ur_bad" => "以低于20%的评级完成一首歌曲",
        "achievement_ur_good" => "完美主义者",
        "description_ur_good" => "以100%的评级完成一首歌曲",
        "achievement_roadkill_enthusiast" => "路杀爱好者",
        "description_roadkill_enthusiast" => "观看手下死亡50次。",
        "achievement_oversinging" => "过度演唱...？",
        "description_oversinging" => "连续演唱10秒不回到待机状态。",
        "achievement_hype" => "过度活跃",
        "description_hype" => "完成一首歌曲不回到待机状态。",
        "achievement_two_keys" => "只有我们两个",
        "description_two_keys" => "只按两个键完成一首歌曲。",
        "achievement_toastie" => "烤面包机玩家",
        "description_toastie" => "你试过在烤面包机上运行游戏吗？",
        "achievement_debugger" => "调试者",
        "description_debugger" => '在谱面编辑器中击败"测试"关卡。',
        "achievement_pessy_easter_egg" => "引擎女孩伙伴",
        "description_pessy_easter_egg" => "嘿嘿，你找到我了~！",

        // Note Colors Menu
        "note_colors_tip" => "按RESET重置所选音符部分。",
        "note_colors_hold_tip" => "按住 {1} + 按RESET键完全重置所选音符。",
        "note_colors_shift" => "Shift",
        "note_colors_lb" => "左肩按钮",

        // Adjust Delay and Combo Menu
        "delay_beat_hit" => "节拍命中！",
        "delay_current_offset" => "当前偏移: {1} 毫秒",
        "combo_rating_offset" => "评级偏移:",
        "combo_numbers_offset" => "数字偏移:",
        "combo_offset" => "连击偏移",
        "note_delay" => "音符/节拍延迟",
        "switch_on_accept" => "(按确认键切换)",
        "switch_on_start" => "(按开始键切换)",

        // Graphics Settings
        "description_low_quality" => "如果选中，禁用一些背景细节，\n减少加载时间并提高性能。",
        "description_anti-aliasing" => "如果未选中，禁用抗锯齿，提高性能\n但视觉效果会更粗糙。",
        "description_shaders" => "如果未选中，禁用着色器。\n它用于一些视觉效果，对较弱的PC来说CPU密集。",
        "description_gpu_caching" => "如果选中，允许GPU用于缓存纹理，减少RAM使用。\n如果你的显卡很差，不要打开这个。",
        "description_framerate" => "很好理解的，不是吗？",
        "description_fps_rework" => "如果启用，当当前FPS低于帧率限制时，\n游戏将防止“卡顿”或“平滑”。",

        // Visuals Settings
        "description_note_skins" => "选择你喜欢的音符皮肤。",
        "description_note_splashes" => "选择你喜欢的音符飞溅变体或关闭它。",
        "description_note_splash_opacity" => "音符飞溅应该有多透明。",
        "description_hide_hud" => "如果选中，隐藏大部分HUD元素。",
        "description_time_bar" => "时间条应该显示什么？",
        "description_flashing_lights" => "如果你对闪烁灯光敏感，请取消选中！",
        "description_camera_zooms" => "如果未选中，相机不会在节拍命中时缩放。",
        "description_score_text_grow_on_hit" => "如果未选中，禁用分数文本在\n每次击中音符时增长。",
        "description_abbreviate_score" => "如果选中，分数将被缩写（例如 10.00K, 1.00M）。",
        "description_debug_data" => "显示谱面信息如滚动速度、BPM、生命值；还有步骤、节拍等。\n如果你在谱面模式下，后者将可用。",
        "description_health_bar_opacity" => "生命条和图标应该有多透明。",
        "description_fps_counter" => "如果未选中，隐藏FPS计数器。",
        "description_vsync" => "如果选中，启用垂直同步，修复屏幕撕裂，\n但FPS将被限制为显示器的刷新率。\n（需要重启游戏以应用）",
        "description_pause_music" => "你喜欢暂停屏幕播放什么歌曲？",
        "description_check_for_updates" => "在发布版本中，打开此选项在启动游戏时检查更新。",
        "description_discord_rich_presence" => '取消选中以防止意外泄露，它将在Discord的"正在游戏"框中隐藏应用程序',
        "description_combo_stacking" => "如果未选中，评级和连击不会堆叠，节省系统内存并使其更易阅读",
        "description_show_current_state" => "如果选中，FPS计数器将显示当前状态。",
        "description_combo_and_rating_in_camgame" => "如果选中，连击和评级将在camGame层而不是camHUD中渲染。",

        // Gameplay Settings
        "description_downscroll" => "如果选中，音符向下而不是向上，很简单。",
        "description_middlescroll" => "如果选中，你的音符居中。",
        "description_opponent_notes" => "如果未选中，对手音符被隐藏。",
        "description_ghost_tapping" => "如果选中，当没有可击中的音符时\n按键不会失误。",
        "description_auto_pause" => "如果选中，当屏幕失去焦点时游戏自动暂停。",
        "description_pop_up_score" => "如果选中，击中音符时会显示你获得的分数。",
        "description_disable_reset_button" => "如果选中，按重置不会做任何事。",
        "description_hitsound_volume" => '有趣的音符在你击中时发出"滴答"声。',
        "description_rating_offset" => '改变击中"超棒！"需要多晚/多早\n更高的值意味着你需要击中得更晚。',
        "description_flawless_hit_window" => '改变你击中"史诗！"的时间量（毫秒）。',
        "description_sick_hit_window" => '改变你击中"超棒！"的时间量（毫秒）。',
        "description_good_hit_window" => '改变你击中"好"的时间量（毫秒）。',
        "description_bad_hit_window" => '改变你击中"差"的时间量（毫秒）。',
        "description_safe_frames" => "改变你击中音符早或晚的帧数。",
        "description_sustains_as_one_note" => "如果选中，如果你失误，长音符不能被按下，\n并计为单次命中/失误。\n如果你喜欢旧输入系统，请取消选中。",
        "description_judgement_counter" => "如果选中，在游戏中显示判定计数器。",
        "description_show_end_countdown" => "如果选中，在歌曲结束时显示倒计时。",
        "description_end_countdown_seconds" => "歌曲结束时倒计时应该持续多少秒。\n(10 - 30)",

        // Loading Screen
        "now_loading" => "加载中{1}",

        // Difficulties
        "difficulty_easy" => "简单",
        "difficulty_normal" => "普通",
        "difficulty_hard" => "困难",

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
        "clear" => "通关",
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

        "reset_score_confirm" => "你确定要重置这首歌的分数和准确度吗？",

        "no_mod_directory_loaded" => "< 未加载模组目录。 >",
        "loaded_mod_directory" => "< 已加载模组目录: {1} >",

        "time_hours" => "小时",

        // Results State
        "results_title" => "结果",
        "results_score" => "分数",
        "results_accuracy" => "准确度",
        "results_rating" => "评级",
        "results_played_on" => "游戏时间",
        "results_press_enter" => "按Enter\n继续",
        "results_practice_mode" => "在练习模式下游戏",

        // Judgment counters  
        "judgement_flawlesss" => "史诗   ",
        "judgement_sicks" => "超棒   ", 
        "judgement_goods" => "好     ",
        "judgement_bads" => "差     ",
        "judgement_shits" => "糟糕   ",
        "judgement_misses" => "失误   ",
        "judgement_combo" => "连击   ",
        "judgement_max_combo" => "最大连击",

        "images/menudifficulties/easy" => "images/zh-CN/menudifficulties/easy",
        "images/menudifficulties/normal" => "images/zh-CN/menudifficulties/normal",
        "images/menudifficulties/hard" => "images/zh-CN/menudifficulties/hard",

        "images/menu_tracks" => "images/zh-CN/Menu_Tracks",

        "editorplaystate_section" => "部分: {1}",
        "editorplaystate_tip" => "按ESC返回到图表编辑器",
        "editorplaystate_time" => "时间: {1} / {2}",
        "editorplaystate_section_current" => "部分: {1}",
        "editorplaystate_beat" => "节拍: {1}",
        "editorplaystate_step" => "步骤: {1}",
        "editorplaystate_score" => "命中: {1} | 失误: {2}",
        
        // Language example text
        "language_example_text" => "这是中文（简体）语言的示例文本"
    ];
}

