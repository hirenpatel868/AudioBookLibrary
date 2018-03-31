package com.murati.oszk.audiobook.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.text.format.DateUtils;
import android.util.Log;

/**
 * Created by akosmurati on 24/03/18.
 */

public class PlaybackHelper {

    private static final String TAG = LogHelper.makeLogTag(PlaybackHelper.class);
    private static final String PLAYBACK_PREFERENCE_FILE = "com.murati.oszk.audiobook.PLAYBACK_PREFERENCE";
    private static final String PLAYBACK_LAST_POSITION = "PLAYBACK_LAST_POSITION";
    private static final String PLAYBACK_LAST_MEDIAID = "PLAYBACK_LAST_MEDIAID";


    private static Context _context = null;

    private static String _lastMediaId = null;
    private static long _lastPosition = 0;

    public static void setContext(Context context) {
        _context = context;

        restorePlayBackState();
    }

    public static String getLastEBook() {
        if (TextUtils.isEmpty(_lastMediaId))
            return null;

        return MediaIDHelper.getParentMediaID(_lastMediaId);
    }

    public static String getLastEBookTitle() {
        String ebookMediaId = getLastEBook();
        if (ebookMediaId != null)
            return MediaIDHelper.getEBookTitle(ebookMediaId);
        return "";
    }

    public static String getLastMediaId() {
        return _lastMediaId;
    }

    public static long getLastPosition() {
        return _lastPosition;
    }

    public static String getLastPositionString() {
        return DateUtils.formatElapsedTime(_lastPosition/1000);
    }

    public static void setLastMediaId(String mediaId) {
        if (TextUtils.isEmpty(mediaId)) return;

        _lastMediaId = mediaId;
        persistPlayBackState();
    }

    public static void setLastPosition(long position) {
        _lastPosition = position;

        persistPlayBackState();
    }

    public static void persistPlayBackState() {
        if (getLastEBook() == null) {
            Log.i(TAG, "Refusing to save empty books");
            return;
        }
        try {
            SharedPreferences sharedPref = _context.getSharedPreferences(PLAYBACK_PREFERENCE_FILE,Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sharedPref.edit();
            editor.putString(PLAYBACK_LAST_MEDIAID, _lastMediaId);
            editor.putLong(PLAYBACK_LAST_POSITION, _lastPosition);
            editor.commit();
        } catch (Exception e) {
            Log.e(TAG, "Playback info cannot be saved. " + e.toString());
        }
    }

    public static void restorePlayBackState() {
        try {
            SharedPreferences sharedPref = _context.getSharedPreferences(PLAYBACK_PREFERENCE_FILE, Context.MODE_PRIVATE);
            _lastMediaId = sharedPref.getString(PLAYBACK_LAST_MEDIAID, null);
            _lastPosition = sharedPref.getLong(PLAYBACK_LAST_POSITION, 0);
        } catch (Exception ex) {
            Log.e(TAG, "Unable to restore previous playback state:" + ex.getMessage() );
        }
    }
}
