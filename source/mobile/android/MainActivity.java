package ::APP_PACKAGE::;

import android.os.Bundle;
import com.discord.socialsdk.DiscordSocialSdkInit;

public class MainActivity extends org.haxe.lime.GameActivity {
    @Override
    protected void onCreate(Bundle state) {
        DiscordSocialSdkInit.setEngineActivity(this);
        super.onCreate(state);
    }
}
