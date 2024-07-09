#!/bin/sh
# This script was generated using Makeself 2.5.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4094594719"
MD5="c72a3cac05dddf6d63a0580089317abc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
SIGNATURE=""
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"
export USER_PWD
ARCHIVE_DIR=`dirname "$0"`
export ARCHIVE_DIR

label="Patcher for Burp Suite Pro"
script="./burp-suite-patch.sh"
scriptargs=""
cleanup_script=""
licensetxt=""
helpheader=""
targetdir="archive"
filesizes="37069"
totalsize="37069"
keep="n"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"
decrypt_cmd=""
skip="714"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  PAGER=${PAGER:=more}
  if test x"$licensetxt" != x; then
    PAGER_PATH=`exec <&- 2>&-; which $PAGER || command -v $PAGER || type $PAGER`
    if test -x "$PAGER_PATH"; then
      echo "$licensetxt" | $PAGER
    else
      echo "$licensetxt"
    fi
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -k "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    # Test for ibs, obs and conv feature
    if dd if=/dev/zero of=/dev/null count=1 ibs=512 obs=512 conv=sync 2> /dev/null; then
        dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
        { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
          test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
    else
        dd if="$1" bs=$2 skip=1 2> /dev/null
    fi
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd "$@"
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 count=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
Makeself version 2.5.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive
  $0 --verify-sig key Verify signature agains a provided key id

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet               Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script (implies --noexec-cleanup)
  --noexec-cleanup      Do not run embedded cleanup script
  --keep                Do not erase target directory after running
                        the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the target folder to the current user
  --chown               Give the target folder to the current user recursively
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --ssl-pass-src src    Use the given src as the source of password to decrypt the data
                        using OpenSSL. See "PASS PHRASE ARGUMENTS" in man openssl.
                        Default is to prompt the user to enter decryption password
                        on the current terminal.
  --cleanup-args args   Arguments to the cleanup script. Wrap in quotes to provide
                        multiple arguments.
  --                    Following arguments will be passed to the embedded script${helpheader}
EOH
}

MS_Verify_Sig()
{
    GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
    test -x "$GPG_PATH" || GPG_PATH=`exec <&- 2>&-; which gpg || command -v gpg || type gpg`
    test -x "$MKTEMP_PATH" || MKTEMP_PATH=`exec <&- 2>&-; which mktemp || command -v mktemp || type mktemp`
	offset=`head -n "$skip" "$1" | wc -c | sed "s/ //g"`
    temp_sig=`mktemp -t XXXXX`
    echo $SIGNATURE | base64 --decode > "$temp_sig"
    gpg_output=`MS_dd "$1" $offset $totalsize | LC_ALL=C "$GPG_PATH" --verify "$temp_sig" - 2>&1`
    gpg_res=$?
    rm -f "$temp_sig"
    if test $gpg_res -eq 0 && test `echo $gpg_output | grep -c Good` -eq 1; then
        if test `echo $gpg_output | grep -c $sig_key` -eq 1; then
            test x"$quiet" = xn && echo "GPG signature is good" >&2
        else
            echo "GPG Signature key does not match" >&2
            exit 2
        fi
    else
        test x"$quiet" = xn && echo "GPG signature failed to verify" >&2
        exit 2
    fi
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n "$skip" "$1" | wc -c | sed "s/ //g"`
    fsize=`cat "$1" | wc -c | sed "s/ //g"`
    if test $totalsize -ne `expr $fsize - $offset`; then
        echo " Unexpected archive size." >&2
        exit 2
    fi
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				elif test x"$quiet" = xn; then
					MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" != x"$crc"; then
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2
			elif test x"$quiet" = xn; then
				MS_Printf " CRC checksums are OK." >&2
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

MS_Decompress()
{
    if test x"$decrypt_cmd" != x""; then
        { eval "$decrypt_cmd" || echo " ... Decryption failed." >&2; } | eval "gzip -cd"
    else
        eval "gzip -cd"
    fi
    
    if test $? -ne 0; then
        echo " ... Decompression failed." >&2
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." >&2; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. >&2; kill -15 $$; }
    fi
}

MS_exec_cleanup() {
    if test x"$cleanup" = xy && test x"$cleanup_script" != x""; then
        cleanup=n
        cd "$tmpdir"
        eval "\"$cleanup_script\" $scriptargs $cleanupargs"
    fi
}

MS_cleanup()
{
    echo 'Signal caught, cleaning up' >&2
    MS_exec_cleanup
    cd "$TMPROOT"
    rm -rf "$tmpdir"
    eval $finish; exit 15
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=n
verbose=n
cleanup=y
cleanupargs=
sig_key=

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 52 KB
	echo Compression: gzip
	if test x"n" != x""; then
	    echo Encryption: n
	fi
	echo Date of packaging: Sat Mar 16 20:04:07 UTC 2024
	echo Built with Makeself version 2.5.0
	echo Build command was: "./makeself.sh \\
    \"archive/\" \\
    \"burpsuite_pro_patcher_linux_generic.sh\" \\
    \"Patcher for Burp Suite Pro\" \\
    \"./burp-suite-patch.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
    echo CLEANUPSCRIPT=\"$cleanup_script\"
	echo archdirname=\"archive\"
	echo KEEP=n
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
    echo totalsize=\"$totalsize\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5sum\"
	echo SHAsum=\"$SHAsum\"
	echo SKIP=\"$skip\"
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`
	arg1="$2"
    shift 2 || { MS_Help; exit 1; }
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | MS_Decompress | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --verify-sig)
    sig_key="$2"
    shift 2 || { MS_Help; exit 1; }
    MS_Verify_Sig "$0"
    ;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
    cleanup_script=""
	shift
	;;
    --noexec-cleanup)
    cleanup_script=""
    shift
    ;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    shift 2 || { MS_Help; exit 1; }
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --chown)
        ownership=y
        shift
        ;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
	--ssl-pass-src)
	if test x"n" != x"openssl"; then
	    echo "Invalid option --ssl-pass-src: $0 was not encrypted with OpenSSL!" >&2
	    exit 1
	fi
	decrypt_cmd="$decrypt_cmd -pass $2"
    shift 2 || { MS_Help; exit 1; }
	;;
    --cleanup-args)
    cleanupargs="$2"
    shift 2 || { MS_Help; exit 1; }
    ;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    export USER_PWD="$tmpdir"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if test -t 1; then  # Do we have a terminal on stdout?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0 >&2
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -e "$0 --xwin $initargs"
                else
                    exec $XTERM -e "./$0 --xwin $initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n "$skip" "$0" | wc -c | sed "s/ //g"`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 52 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = x"openssl"; then
	    echo "Decrypting and uncompressing $label..."
	else
        MS_Printf "Uncompressing $label"
	fi
fi
res=3
if test x"$keep" = xn; then
    trap MS_cleanup 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 52; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (52 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | MS_Decompress | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        MS_CLEANUP="$cleanup"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi

MS_exec_cleanup

if test x"$keep" = xn; then
    cd "$TMPROOT"
    rm -rf "$tmpdir"
fi
eval $finish; exit $res
� 7��e���8_�.��m۶m۶m۶m۞�ض=�۞��w�}���=9�����&w�;+�]�T�z���Zt�B�N2��&�NҦ��vtV�N �G�?����_=#;+�\3���G�������������������}F6&F ��4Wg�ޗ�������߼������{��������)H�� @@@ �t���'(   ��*���rb���r�b��*t�b?�  ���S2Ҵt�ҴT��s�J����Nr�K�R��R��rS��+���4tr�mJ�T���������$����XX)�(�eg��h�������������{S�P����$�xt������Rp�o%�I�l+�/ˡ    ��!�9�/���b ������F��$,��A�;��ɿF�_��������_8R�� ��hH)��):9���:;Ǫ[+��b��u;���QG��	(��:�c�-b� V	ƚj�1t�t���_ԩ��L�ְG<�-���	a����=oY�ȟ}���=�1�(��Z�<�5w״�r����{����������e2 �;�b����qA���͎
 �l2�r6@r�@m"�Υ�Y��w		�D4[�%f�\�=�	���G4��P�q�g�}��b�ū�,^ß\5f�	�?耭���_�3���~�������%?�V�|���m=H�x˄-W�QtT%@���W�i�lmjUg(&CX�4��X�!S]:m���\��&(2���k.n���h�4�-�N�U8?��u��=�Ы�G;x��-!��(�Y�����-}^p X��S��t���l�����G�ɺ�*��o;O�`��L���[�ܽ���-m�����Zܮ��]d�)D�|V��ׯ��r@��0gwUM@�TK���mh�OgfA[!bр=��rX+vm�T>TC��`�`>����AWr�#s�_@`�`D*{�%�?6���a����X�W%�(#6�_�#Y�s�=���>Sf�=@R}���GG�fi�X4�Id���]t�Tgት���u�XV���z{�C���(���J(X��o�A�ķX'�6g�x�򋳆y���#0��a��ï�(< ��숍ƺ)�!�c,9�s�K37�bŊ;�
���wP�����"��V�4J�S,1GXEp\��3��; �ū��}�  ��V:�k�B��e|��
q	&c�2CA���9B�L�2�����"�˨컛�H�Ea&z?���G�*��:n�u��.Oe �?���R 6Uy�VJj"�I�2J�xid����7�����WE�u]N�[QE��o�&���Ja�.U��_�r'��B+Af��&��Le�r��ȶt�O��\]Û�����U���~S����8�e�817�:�P�K�?	��tʱF�����+���A�ihŬ��*b����mԠ���5&"˗��^��dM�w��\PA��?8
%��(�>�ȉ7xAN�"X���L�pJ�u�\G��_w�۴֙7�%�oV�|rYD$�{^��a�"�QEK�[5��	|11���+k��`�}��K\�e��O��첒��R>E+�4���e��/��Kغ�a�_I�G�fu�h�����.��&��4�����$Ӕn��XalĂ�N�
Jӆ���:c�<ɢ�2�3+ ��ɐ�� ��5�}}�|���x�a�r@qv�yt#�7��%��D�|�1@��B~F;�K�@�EQ[\J��]��z�T��ڍ'>d_t��E�!э�����[�̨/��/���5d����uX%=�Bl��5���K�Q��E'G}ڭ� ~+��ۉ��`'[�7���Łs ����|q`q�|q�aӁ��~�=�p�9�p�y�K�6 ��!C}�����l�\��Wf���+*��3+�\u�uMֺ}9��v���x�+�#y�J�
�7F�u�Q=%�m�w�
����jd@1��4Y�|��˗�PO0CiP5Ğ�pm����U�#H������{P�#��O��Cr���:�E{��U�$~=���+���o#�@Q��4d�������'
Z�c&@g�C>-������'ݼ�\��V��o�d+�^C�����0	ē218٤�|xs�ѺO�n��3ڳSm.⯩o]��Ua|v�gLK`�-f�$� �W��3򢼉VD��Mh�bg�DܵL��bB>n��qs2�n��7G��&ⓓ[ҹ�Bx�	�WG�����8oc��\q"\|�{�3�5e%G8�a�F݉�x02�	�	�@��5&:���i��s�B�s�q�Jٚ����<�B�L��Γ�r:���[��W��oD�BRqB~z�|�?A�wU_%���$�h�7c$z2�2%c�M2�Ԏo>�_喽.94��T*b+��
�e.5&�V2�\2���"&��4��s��e��d�ty����)�R��?Љ/��nD�q��M��#9��I�1�Dq�'f
���sR���.�a[ϴ�͖:::�v������ےabb���	f���*�<:�Gn����	��,4,�֖N�-n2f��;zd�<�`����\Ӈ���ϔm=K6��g7�6ƧU�ƨ����&W�^�fz��towMuJ���7n���;�ܝ۽DM���H��(`'�('m��J(��2m�1A���)�;�2d�~�Pʕ3�q*��s#ǥ�z2��F8�8�v���Z��K��֍:�})a=2
�Y/�?b���¾d�<�o����#��7x�y���
� ۢ
ks/B����Xtw����VF�)���Ր�;!n������������)�:�ڸ�'aM��T@��.?��oj��(D�*�|����)L$|��������ʧ��{�PX�tW�0q��4�{�}͛��0���0&�T�sk^�2�'<��TD����a���<o��R[��y�>(�o�1g�7����3�zY��&��ބ�p .��Дs���s��`�N�����z������d?C�v��q���6PO��-�mq�ӝ��S�{?M���i�jC0��1��#�:��(�+�m�&f1�Ԣ�Ha��yA1��R���[�\�h�JJr����F�4n�N�^�,?zFLt�&c�3a�f��x��U�\�O��7~�&��4��"�<[?�md�����Z��� `��	�?sk�í卬L�]H�k��t�Qx��m5��(""D�6�j豐C�
�	6��=�v�k��6v��D��#G�ЏrWM�Q�3�o39�_g{��ڥ��) �3F���pG�atTKHTyC�����`S0�ؾI������i�~��.B[�|aH+���n龝�	����$b��c6�^!�U�l^����~WL��f-A�����|�U�a,�����ï�.�Z;�����yp����Gf�LNˇ1�X�aa�&�3&�	#uF��q�\����G�C�����£^Wj��C�ݒ̿�0��s�����D����:�a��V�l��(���D'v}�*���#��b�c����%,�M��h��*��BŅ=�"���`�T~8�e|H��S�̇���
��� ��y�_�����йq%�OЬ�w����r%+��,b�y��E E�\�ic@e�a�Չ��Hn��}Зq6�tt�����ť1I4�\a�<3�l`������l�o Q`�m"�r͂�����o��p5�����w���8��3O����-9dE�%9�!굴l"+h)m�]-DQYOK�0�0sz���7l&#��o�����@�I������.���~����y��(J�)���ASա�U��%�Q�!�#`X��p,��x�4��q���$��`��N�?�,Q��Cf�����+��9H�y�l�(�+߾��k�a Ϛq��%�/<Z[�Z�=�R�Ω�N&���^l��/8�ߨk�\����x�����!�6��\MyǷ�܊ҝ�>ʩ�mp��t�R~������t]}�Y�����L_�߬J�Ke��ڷn�:E�w���o�p��/ٯM�8�-ta�`�=���kG_$�M�'����7{�5��1X�Lq���äC�H�uc(
� ���Ϟ̎�m�\�����`�ؤ�}
�u��F���]xe�#Ɖg�1 �	���r��0�bJt�٤%��<�62�#SWE��<5w ��# W{I��Fc���ѝ�V`����-A+��Q���N(S��U�;�LC� �lnB>D���&XS��A]�H
�h&�	Ƅ�=Q=A3@1QHH!�X���-
��E�5�E,Z��$����2���$�F��Փ*��jR�>�)�����3�)���Apȿ�$�_=�b87�VyK%4�&؆P��$gԘ"AkSA�0���1Aa�m�������ȿȴ,?I���Z&�>�<��[����#�����wNoG�����p����SÙ��(2��NELEC��D���X�en��3�t���)]Ч� m�*�>��'���htI�&J��{���N�83��	i�ri���6�	hu���Ж,wG��������C��&�#'Kz���Il7���]e�3��v�����YVhh:����)�3Mb���
�M�	��Τ�o�Ӵe�.s�vUb[T0��8	�����mvpaJ������D2���\0��P��1��9������Q�Xs���\F^KzG=�3"荖4�e�0�X@���S�f#�)�'�dM�9M-�d붡&�{Q�S�2{��_e��ý�W}d���3.|��	�v8.a�尌�)aýZp��S
ԸiKf�J/��K�cjtUl�]�T񘃌S&�x����P-�u=m�s�d��AG�v����CT'*;b����bm!�΂����"d\�渣��BiQ�v���|4���Er��g۩q�F)&kі�u���v 7�����d�V��]��AEF�ar�]�.3g9 ��A��u�8}�b�N���9_g6�}�KM�\��]L�k,5�v�_�	~��bR��i�lmVZc�S��@_)V/լu�-�8���x�akow�g��$s��wW@�dӑ<ydm������nSYǖ���o=��#�P6~q��[��n��OПa/������P<t�����YkD����x�_��|7�� �.Qvg �|Z;v+|��Ͻ�}� ����pb ���!^1ŀ�$X��Q�,G�Z�.���+a8D4�[C����n�&M��o!��)�f�L�Gb�L|�4C��yo�'��>�-���E���D�o+t�*��?�-��^q�4-aE���d�zc-�[�7�A{H��%����Q�A^u}s��3��~�����"��!ݶ���y$#S�9��K�J�?��;]Q|�יg��.?!c�5P�ۜVvB��@}�Qյ&6�N!(�aS��C��Q���gM�W�tY㹼J�Ku1.�&��y8Pv�9uY��t��/�&ۥ�H.�v2쀰ϙ�iM�S�va�@�h��8/�&ڽ�${�]��V2��K�1�JI�`�Ib�����2�b�@u��N�<�U.�P���7̅Ce�S���-�P��F�dC�S$�O�g~)䝊��ܷC?�������;��9��m����@3���:�\�l�#�b�ٔ��55���i�oh�WJ�?p�&��Έ篘����s��F�@�Zۮ��Op�4cL�#��4��A+�5��Đ�˺2HRqȧJN��hŲ�D6�M2�%ޥς���W7��V�������L���=�1����>�n^Y��wӳP_BI�2J����S�/�(?VѾ�"}��t�'�v�'S�_�(?n�>b>vɾ��ا/�ߏ����'�#_R��s�������7��٭�KɏG���s�sl�\��z���z��5��o٬^a��۲��9}���"�%�E~����e�=�X��>�󽤧[������9�o��n���_�iɏ>܂��'�,���3��窄'TE!|bE�� VC�UJ�?�	-��r֑$ˮ��ET�h�V
� /Xs�%\m��5<k�FXɶą�s��@R�<e��e6��@B��3�ڔǑ��Վ�CR���qT�!�fɅyD����2�w����A�,9g�Z��� Eg�9H1�v���˰���<neйE�:"��h�Vf���9�<,j�g��&������̍��l�)D�Oxq�a�4�4f5�CA1v�z����8�N����$�'�c��m���k�g���׹0fT�	�k�%��9�5�3˖���m�Xq����0��}|��I�����4a�:�A<���L�5b���	"���1�w%�zW��Z�9�~�i�@��@�Zkɣ���D�BzmNv�n�K�
x#���d�A褕� az���/�JU�O,�{�>�92�"V�1c�uN}�5�tH�j34P���@M��{Rp��ԉE� �ĸ��~~w�c��ɷ*�Itj���m�%�eN�x\�\�S�+����L��I�9y�C0]�E�D��t	��W��;b �.0�6�[_��[��ƯC w�⥃��ce��-��n/��ԒvD-��6t�t�5"�e 
~44����7kvT��T��CK*����0<�	��P�����FE��G('�l�q6;:��KH� �i�(&�$��iΜ�Tk�եC�(@9p�E�� 1k�jO�~D>t�E5�	p4��Ԯh7����C��BS��P�v~^�4k�>�\��J'E�61����Ǧf&�wu��rN}=։�.�wT�x��2���T��y�BbG�N��"|�w��E�Fa{��t�q#�xtH׮�fW��켧W�³_����U��ڡۼ�h����X?K]ҋUUvYQuW���d\�P[�%��݄_*�7��iWWl<�ʄ�h+�h�d*�<��#�p31�BZq>���_�j�{���S��R���=�O�fZ��ەV��6飺���Fe��CͶ#�muܙ�T �{ۙ&إ%;YaH���m��]7�i�U��3��j1��6����n�s.�3�4#j0;,2u��QD��ΩSyřQ��+��s@�P&mc���,+�<c�6[.�cɮuٽ���n*;.�x��qGg��4���K�@�>+�+������w2{m��M<��S���;�$c����m���VZU@��q��<,[eò**5S�K/d��� ۪4ꋾC
��_Gq��M��q��|2`YǟQ3��/_��üt�C+��w:k��8V
���&�(;���*����JXP$[q�\iD�Ut�u�?㨇Z�P�s.�.:.�x�ǘMזYo*�{K/zm����O0�
��@3�ب��d�d���U&h�a����� 6`ld�
����J�t�1wX��m�R9�Z	��*��'��l��ҁ5Y�� /� u����1�_tC��N+��]��H��Nu�:�9�b˂��.���R�o�����n	�u���H7;`X�c�٭��U�|f�p��;���"�(񂿭��-�ʳ�h�%T�t�8��B���]&�;�0�n8��KFK�h�A�D{'���ed�p��\�P~�]a�uH!���[���:��@���� 3�p��و2����Jp�P�͘O��g�i�Y���5�b����e�=�N�29?�P&�bh��qUJ����Z� ����PT��N�skg�m��\a-A��.�ժ#��b	�D�.s(�+;	,��-�hC���OvP�YI���P4��<#�qA�nv�����1!^�恨�&k���A_�e��u�jQ���٨��B8����(+%8�@H�n�$�D���QF]Z�Y̚��E����J"���!�t9OC-�^��JJ�]{!P�{Q���* �!l(�P�ߩ��`2H�c�58�±�2 N��/�B#`�p2Ў+��k"RC�u7�dP�] ��,K��`w���2�I&�$��5��[(�����y�D����RW�&��� ��#�n:����l����H������˭�DD%jk��Vc����3Ե��H�gb�!�J5��x.� �3���~�Rs]��Р��ͦU{P> ��J�aj���-��i൱{6v���J5Q
���f��1;,�:�#Xmdz�󢇫W���i�˗�[wB������\��!ȡ������L�B^~!�taK0lp�C��O>z�/�/�V���fqhx�)6fm��sl�Qv���}�&܎�������f\<f�����>)��;x :�L��l}��4:�lC0dg�n�1��9=Ő�7�  ��	����|�S���j��h�+,�F��d�k&��z����P,��kL�#�7wdA5�iji�	��Ɏ�,>!: N}X��f��_��q&�N'��=�Z�{~�}��w*s�@+�'<� �#=w�:0�k��Ό4�ZDNP�A!{��6�:P�fqG�NkN��0Od�}	�T��Ky?��ځ�N��8qτ0Ua\)4F>U�|(kڗ�u���@�/6�cɫ�X�������X���}��ՎP����Cޢ$��	�ݼ�@�����;	�v Ԟ������5�{���j4��X��V�?&݊�T6�|�>#���w$����˰l����؄�K�lW�N��E[��FN����p�Oڀ�?�RL0�nRw�b��iqZV.�x��y]�2p8$P�ĮnD�KPb;����ƥ��E�-߷��1��- Հ�c9!���o��R�(�uC�?밤k������1�p��B@nJa�Ȳ��Wh�e��V�<��~0�q�Z��u��H5>+ݟ�E���%DK8S��1s3# �b��j��É�d$����e��o��6��>�He�
ӎ�Z׼$�Ϧ�ǔ��M��H/q�:��o���\#�=�Z[�v�ˣV���U��SB"$���«��l�4��T6%r]�3�M9�eQ0��$�n��!��%�g�t�M	�,�dؽr���3�'�.�ZY��J���1(��A����I���Ð8G��[��_"���p��b٘�ϼbkL^�ܷ3�'"[����r�G�\��Urz_fn���p�>	��&t�1t�x�F�g����P��ei$�L%��DQ.�~�B#��+��p���yӬ�(�*���%`�g_���<�e��ˊwT��gI�;�MOH�&�I���?��#*%�sbjD�!Cn� ���W�3ޔC}�@�m�||Aonn�ƫ��6A��}9��j��p�@�2��Fp��D'� ;�4/j3�~{�����'�d��vq>T}x�Q�[}���|���*��j�>	�r���>��A�C�e�^<vk� �%ږ<����'cĥ���+/��{ ���<�ւ��6��8ݒeYK�-v����yC��Y��B��֪�6�"��pb�(�XG�?7?j뷾O~:�'����V����15��H1V�Ē� ;�V��� ���MXW��L"f[���j:���u�&�a.m�YW�	�j�\je�@��p�((=�Q9b���M��TGfc��VP�D��?"��qGx�U����U�6�����>�p��_ �a���kچ��V�᷾km��y۞r|���w�q�\qj�{�����J��J!@�.����J>|H��%�j�����a&�	Ix��ꂝqYz���^<��$��nTt�n��rb�����j�X$���6�j%�&i��ǅd/K�M���J��-)E�%��]�xp��c�� 5:�|��w�g�Ш%j��m�:-�v9�'������.������E�"��q��"|�;i�#�PS�E�����-�H���&�� �`U���Z��].+����A�𬰵
zAR���qlKN�@�i!m�I&ۅ&����ڍ�E޸f�/�j=��xQ���K�������>�ﺴ#r��wVf)���p%R�!3����g͍��в?���|U��$��L�^�>? c�| �%x�[�̋�-�A�Ԏ/*��X��TZcks���4�<$s0�K_~hP�tt�	��_���0`���­N�N͈��{�@V��e�?@Κr�#g�]�ǁ�#���� J�k���+�_h����*�)l���0xm������G����#���8C�%-��w`���ۄb۷��iyo�F/:�� ƣV!n
΢�\CI�n��u���&� X����xMF8U�/g���x�!x{�jx�B�Y8�<�ED��%O@�+:�Oˁ��8����}���ͦl���Q���W,΀-�	 @���e���D�����?�X�Z�>)Ǚ��:{�ɐ$Ā�bQX{�$*$H� p��&�q�ɑ]�V���;v��h�Z�m���"1�vћv+��n��Ҩ�cv�n�Z������$_~�	���^��o���߽�cx�I4��B{pJAp�g�^j��AO�uR�u��AO<=
��P=%��B���"��� 7~
R�%���SOP�z�gc�\�~E����NG��O̽_:�� �d=u���o_�B}P�4\8��k<G���0�6\�[F��U��K�
�����C�%~e��+�~
�ߑ�o���~�C��(����u���/�z��e<���U��@)�*T�#�
j	��(VD�J�Vi��jP��VTATUD(��-SL�0��*�*�EA��Fq�J\�GP�U.�EI�q����˩���2Fq �!�?�d
n��N���DЫFq`�T�L����W�(Q'��+>o�E��i���uV{qgU>7��=�`'�6��6�mm�=���\�����tW^n�і��e{+��NhX����F�M��(�Y]ĕj�a���m#vs�]G�����*Gֵu�>;�/CC]�]_ٝ]�k��2a����#�{TQ�"ʖmM��ާ=�z8��.aʖޟ��0/����K�^�ɫ�~ Zk�)��d�IBkqb�n���������o�Z$k�*����_D�<�D�Li䘵
r��s�A�4@Gk)���P�����`���*BV����RobN��kW��jr=א���hAAr
$�=`��JPV	�#`#��^�fZ�I�9�p�c\t19��Zn�i��	b.����Z�ܘ��)%_E\) �tf�iꉹEP����RD�%j��ҘBm��v� MΉ�$�2���/�D4y��=��&GV^0�hV�l*&\��!�q�r7ͅht+��i��$OZ	i��OzTj��	$����tw�2AC��W10�۫�T97�'��$�9��C(.7��,��	諻�Zi�E��۰�9�l�'If��D��v艣M�>�^�JL���N���{�.�J�,�E]�^�>�01�đ ��V����Ά�5���K�\n��b-V�Q��D`�V��ffw�Ģ�ԈB윴���$���ݨ:Q��[����L�rt2�������B�r8Q��Q]9TU��RH~����-�R���2�bo�T����J_��_U�Bv~Nf�͔�H�F�����O��F�>�2�z��3n���h'^ND'#��Uw6��z�wm�dEN.35U���������}v�����JK?e������/����I��Ǐ��NJ�!uNP��ƃI�ܧx��N�"2��h)�t�	�[ۺ��<9��e�bۦ��{�:^&�"꿀5k�{>o=��3[7������x|��ෞ�i�8���C��}�_b&��>��V4Р3�o��h���d�N��g�]ɽA5xHa�_Hn@�V'�%<@����c��:�n��:���tTB����H|��\��̓y��Eh8PM���t�]�wnx�IТ��0B���i�WÇ���P6�ě�ȶ0V���[���	�quƈ��zw)���^�6w12�Ĝ�]`1���_�0���ƅ�aʭ&�R&h�~���:���	�	 �s������$s��p$�s 버���U�����a,�8�F�����k�k�5:˿��l�/zy.ϰ�W~ݫ�g�Pd�y7��Y�I���I{)�z+2�U�q�'hP��.��6>�X����llv1mt�u*χn`�)��8�������zrG�9�N=�n��|1�H3۬1��-��<�Ј���h���]���yƝw�a��mu]_�g��k"�fǙͳ���,��,1��p�]d_��Z�ݜ�_֙igYg�����Ī.�w ;��&�l�n����w����r��U[��=Wv��}�9�s���%�pv�Gf��N]b���
ޝ���u��H3�̻)����qƁ�L��n3{��Rb*DO��YrؗXZ�A�i,@o	eB���/��t1��ӭш/�t7���^Ue7̼����gr�Mхa����O�0���v�	"��,�:Ӯ��μ��I��/���T|�s�	p� Ĺ��k]�(�ڱy+���{iq�^*�>�l5����cy0���uuEkW�h ХM�bܵDG&�2����a+.�E�;�[z�	g�����o	�c�`x7�Ä�7� �sҩ��a�u8� �Z;4��r���E���{L�L�~+�4��q􃌲D�D �w��m��`���4�A׮ ��0�κ�o\ �8,"�
�5 xie@��d�<�l�, �g�C6�Ĉ��U`Q��:`��i���GYet"I�%�7��@.5�
�����We/ �놺1᷂�[�Zf6 �M͘��-��dA����&þ	�3`�9KԸ�& ����s�+���T�b	�J�7� �	� �w���`�)`�1! ^��[�\	ZvaR��goC#�-6�J襮��5ô&S�p�T�sk��r`р�B�o��1�ע;=���0�zڏ9��r�ǔh@87{�Z�E�{#x��bs�������1$���$�Y��|@vcq�A��l �Ǣ�,&;@�$��`-�R#��ci�l��@FtD7��_`�!��j0�hd 3`uBmCd��ɢ������Я`6�^X�#q�k�b5���%He�����(ӱ`�V��@��s�\ ��:Ψ�@���	����t0����k��q�`.�'h"��헑�N7�`j��FgƬ�Dp�x$�-�0�-�'�Ƨd��k�| ��w0wc�-�����߇�D(��0pr�`�ÇBY�jp�_���tڗ���!��8$�%n�ҙK]�$��1���,�
�s�d��Y��� �ǎ ><�?�cRת��3����5���<�2h���;��͊�����Q��4,f��37Χf�J�2�w838��'��E .��!$ȑ P��$�J� �ֱ6�Y�ќ�i'J����d��p�`T<�t����'@�
���z�A��m���GfsV="h=BF5�F7L���!NЀb	lW�Nq�����u Á���9���dïۧ���'��4(
���Oa�a�K.^�4��&���Y��g��5�s�-CZ'g_b7����OB��o~�Z؈�`�o����χ�\�\_R��#!�e䢭��xzʋ��f��s]���a�FG�9"�����K}�Z���Va���T�g�]��cuy.��9'v]~l-�0u��K�=j��^ǹ��{넫���y8Ky��ϯ�n�x��'��+5��Y��ɟh�D��u��X٭�n"m�>mM�k�U��Z�������b�6�ZXw����[;� ��8�޾0\��O�<���7a��.�� ���J��#��I�pk�zW�������ԕ��*1��'nS\��� �Ux�r'�
�:��{u+��PG��5�_�p�=8}�f�p�@Z�⤄z������O`�{Sm��`���qp���t����og3�P�/ו~�J��7���:�=��]"T)n�>��ߏM�*�ϖ٦rGH�s��oF�BQ��*�����V��'}�� ]�Έr��T�R$�-�L��h��:��}� eW�L-���8'w�=�Ǆۖ1�# e��/XTF�d0m�&�f!Uj�/�+plI<V!���t7?o�L����B��*?�����v����(�?�P�F����[� �v_�E,e��O,�<��"��`�N4��UvW$�1#�ȟ5�hqm��Z9��-T����sbg�k�\T�4[�c
��T�����f�hfSU�'i��cP�vy�QZ`_��fXf_^ag1O0���,��/�p�9����:��eQ+��:�Ru�-�l	����-qm�]%��޿�]��>3n���>�nI}Y:fP�G^�[L}�9��B�b�d�$�+ɐ�A��F�H�F�aHf)	ݿLua�.Q+�E)�+�:�zm8U?���(�>��/7�aθw�����`gqpGv�)`����Q�E���ɋ*���+4� ���:>ĘQ<K��*��
�	����NF�/$���#?�[|HXC�x��+W��H�Cc�*/8U��B�C'���/�4AB!ļ$�Mi�{EeD֤�2�a����Ȇ�
R����(ˆG���i�t5�Ly��
fM�vM����fɕe��&�L}�O��Ć`Ue.RfS>Zzc2�B����P��<Af�XU.V&��Kك� ��_�f��+xoC~m׍]d-�����O�����;���U4xzSɍ�@�����92%�N�û4���E�A�m=E�9�yQ�2Zh��|4�SxV&R����[��^c�W\mH
TI��Rg�k0�z���E�np�z@Z�7� w��n���X�݀s׀3Y�sڷ�r� ���!���'@L0���9�t>r��Z#���s��2����C�� ����Mj�"�(�s�C�.�?�������i@T%�����܂��	@y�g��7��Ĥ7#W�Hr��"9��T&z��~�i@�Hx3�wi!K�S�Hy�ys		V��_=(��~/�
�v4�q�ƯF1�YI��Ud�P~�MVh��,g5�k���#Pd��$�߽����|D����F&x��"&�����Li?(z��16R����*�=�j�j(�����X�xe�}n��ć��{8�*x�s֑�s�d\`°�,tی�˜d�X�����X�ם�ߚ��J�+Gg���6S�� M���u��VؠF��m�D�BxVvH�,�5ʰܙ�Q�J7;��|bU��W��W<T<͵�����&X�<3��A��ƴ���?�	�zb㕺] dL�Cn�P��?�<Xt�M[h�����$>f6�%�l�}����7 z&8�&��j�� ��lx
�^
��e"ȇ��X��?�_ �餙G�n
9���O#|=�^Y�W��M.� �R���tS���rSjN�>�y2��q�-��l�w��� -���t|@-V`��?y�7��FGv�V�=�)�/A7��0��G�4S�nI��<����ߏ�?<�/~�wJB�~~�\��|�	���5G�/L��f͔fm�:���D�z>��_aM�)��$i���+'���qh�a�La��)|H����S !� 	����}.{.��y*�P�ŔKkԭ%�:�y��'1�����<�= ����݄���hO�:ݼmf��j��V���2�}D�x`]��v}�h����i�3E�]֣SA�d�����ߣ�#�G�L�[{xi:�[ ӭɬwpo@X����{��<�"��ֺɚ����'��>@鷆g{����E~=K,P Ph��L�����lI����QEQ[��M�������U�4Y :�$�M�BJ�cbWR��{��LE�q���ǡ���(����|Y�ܵ&���q�����t���������'>���G0$.��EG�Zj�Ra%qt��Wc��I�EFl�����L����j����?���CH·�[�C�a7�oh�F�$��nǱb=4߲�n����B��dBX��E�R����8T�<\��r�L��f��`���CH������g��?7~�>�Q�ܕ�\ї�8�)�l��q@�zf3�<(�DA��6�ha|�sUi��Kܲ��~EѬW}��a+G�$��z^���h<��N���C��)6L-���YK�4���so��ǳ�Z�_W��8Zl�������7?26���d��Asä��?���my��
_4�x�i�u5���n��s�>;K�K��P1A�1m�Te�S�a�b�G�QL/q� �t��R�T�6tY��N
��RӰ~<A��(�d?�m0�#�)���M8 ��˓i�����/˥1,O:����W��Ǣ�,�JK�W�"��E.��}e9Q�R穴`Ü�l$=��ɛ'�r}�ˁ�����e���@��܊dw︻�s;�t�<�����(���G<O��������[�+Ħhc�C�/��g���O��Svi��֙U�7���:1{㼐� ��r����Ӄ,�6�h�}����<��Z�q��)��03-��<v�1���aWIP6��
6�7�ry�X�WO�ODkz^9h�w�'j��Lx�1|� �a8oؘ�X���H޾��ߕQ�r#J8������G��u�hƇ�sOҏ>�{�XȮ�1�8���⍉��X*cE�U� @�����#���7b�6.�#{s��飳�ʧ�\���C�儳��+�'��N�4��1�Ԩ�ݦ�R�Iny�0�4��%K"@�bH����D�_B�UR�RkCkZ~%=ՋJ���lΒt���{�W��p��=�;���|�͍��,L��H�Vj��Y��@��L���:�^v�}���@��J⫝�u�I�띵:�Nb�#;��^v����G-y+���������'�՛�K/z{~+�_bI��,�?>x{_r��4D���וVt����k嗂�G#
MٕW$�����eWrF��D�3��xl��e�7��?�_vV���L������7z�x�������?�.��ӗU&�XOz����m�%ӗY��Q�����N�/�x[z���.�!,x�ėS/6"����@_q4Q0�ul�P�޿�tN*0��hĉQ?'z`�_�8�Az�>�f���|oѦ��V?}l+�\_Q�6.�2dUy��f�t�шz (8!D�pM��Q���9V���S�٩+�h`$$�,��H^c'�^�<XA�uf0���0�{^#k6��A��lŇ ��<�=hUN��gѱ�j@�T|�iHZ0��F����(!���qrYT{kz�]��1z�(�^+-3b��3�ڸ�MJ�Z	�ryj�+	Y�ՊhU�B�|r޽Qm@�/A�zQ+�B�?��_r1�1��W��;�=���T��$RQ02��_�T�A�a0?��*_��N�2�棐?��h(0��C|3K�*]���H���ߏ�0��!#�|c��
<0�EUm/�0�{g���x�_ {K�4ĵ�|x�Ne����&|�yHco�H��]����RK�-5I㏌�x*�j��tzVk^���w k,��9iT.Ar��7|)��#�8\N��I����sf�o��R!Qs�^���y���)�r��C��C�o٤�¾b�E~J�y��نQ��@��9���|���s���z(߸�VlѕM�S��O��:�V*��9\���)3�q	�l$�o�"�)+f�g��~M���Pj?4h(Q�3�3~��k*˖?y�]��Y|&�fp�7�Wk�G��z�k
�������"��Oh^J.<���I�'�<���V+�HeQ���[�}*�`����F���!*�JoM�宮���V��T*��������޻���m,8(Y���u��&y���5X`��N,��u�B�z�T΂��_���:���ߎ��G�����6΍4�ɦ~t�N��)cI�/�O���S�G�W6�2�_:�����.:!_�*N�'� �K��[X��Gs=̋�ox0�
�ٴ!�%o�2NzL�f�p?,11B�K'SU���'��ᩩD.�P��fA=MX�9A��aE�}�2VG(5�TL��GD�LzU*ѵ�j�h!�k	�J�D*�KP	E���U����}z�`��v����w#�7�-+O�?V�\~��t�� ����^��m�}/jG��
_~��w�M�5QV��
�oCCK3��ԢL�Sо�͎Gr�$�P�\)�hW^����,i�^"��q��m�\h�i��Y��i�WTW\t�`�i�y�d�Vq��Yƚl��y�mwd�t�^t֞m���N:�*;���ʬ+�T��x՗`�UU�Xu��i5�Y�B
b�����$�lŗ��`R�1�V=�L;�ʳ�N6U�UY�X�Y�U8,.��*ڎ*V��/⌫���i�l��`!���a@J��n<��4�.%�wE3  �YWU_��q��#�`�t,�@e�\���`��z��Y�rR���Y��7��4�`&�r����E�v��U_E�1#Ņ�h�w�O�ᤖs C��.�4�L_�A֨�
w���������=����F2^.Ҭ�nd���7�#�5���h��8��*�A>f�U��^��i�ϤD@���Z.��>�Ls����hҽ��33�I��7��S ��j�#Q`�#>a@@ ��4�`B�ʪ��Xd�9�Cs��ې�jW]zܭ)��z
�����
T;��#�Ba➰�W�*�#�T[z��-�t�����BZiS@`0��BbP���������<�ad��qu+�M�0��Q��Ȍ/� ��Ej5�4@6zU�M( (;9�c��&lܱ��o��`�P����	%����i��J!7�
��>�H ��P�As�3�\�
զ��J� H�UI�΁_r�gN`� ~�J�g��Dib��K8�ꦰZ����
�G3�P�p��� ��;�5Mi�m�( p�yfYa��8�6k������w̸��+��m�69
���;l6#z$T��B���@��V@Y�U?����[H-YT�e� �{8�rW���r3m�2�b'�4�W�!�#0R�1W��`%q���a[`VS5�\iU�.���o��\X̭���IV�,�sĹ%֗�Os�2X�����j��4�p�'��� �_
ٿ��8�(�΍�O"'}�hڐ1y��2��C4����P
S��f���a L������ �ChP�o��N$Ж�FΝ&]���CS��0�"�>0��rar�(�Ղ�0���x
ֽA�R�6��uS���8,�̄7�.�:���܁ďy�SHGu\��׷�)YT�Dö��c��g�8w��=^��ڠ���G�#0s{�*�"��rӸ9?x���eA�;��2]=�G~��Ł�q;�9�4[l׮#�P ��M~��4��0w�e�Т��(�㽰ލ�A�n�y�+z����2TZ�#_8q��R��s��7#�R�?����is�f�b�g�9<9g|6ت:�l�+���MT�;5�C+`���&��3��F��BYP�t|��Ae#.|����"2�}�����8@Ƿp](R��z5���e0��� #�1���p�*Y4�н��7�*hb�H��7̀ų����r�_�
w��U�1��ő�r��ժQ?�>��Z'����!b���:��F�>o���Bi}"aݦm���%b�l��Ϛ�E1�Rd@��Ex�+E��Xǽ�}��>���.BJ9LV��guw��^��;�yD�>J���{Q��\�ҹ��Ph��.6}��Ƽ�:�m��&\too�Be���i��^�9�r壱��A�M�N��z�}ah�`ʟoXЎ(0)t�џ�
Z}dߒ�ċ�esYR�9�hp
��7��TlL������� ~���#�v����		�OE���ŷ�S����oߵ�S�ߝ�s�mf�قk#_���E	{�#H����k��|;�}?Ⱦ7ŭ���i����z<)�梷�yдR��)� �ģ���2N�@�`��?!c�#�[]z@�vC��;�K�|K�I�P��� � =�TC�����,�V˯b���a��\=}H�Ƴ��9fy�\{�����jq���Dۛ��L�N��[�������5���>7N��|�.uP�`����zk-֣�w(f�KK�*v]kC�j��.lM�G�9G3gs�l	��
���
Ƿ���n۽I��%�f�vj����ef����K��ը�����+d$��"��r��;��`�����#���:C���Y�E)��ݗ��X�����6φ�����S�D�H��/� ��G�D����-Xne�.���r��K~0��Kw���`Y���a_��¶�~�߃��>�۔�*E��Ђ�8m�#��G�?���M�%q�[H� ��'�� ���e��:.ώ=�_����]�zk�y�'���t����<��ivd�%oj��?,1L�"O#���g�8X�{����N�;�w~�Ϝ7(Ķ�IN��㲿�/��Á_�9�Q��"-�%�n�Tb�Y1DG�/k�F��vn^���,n����Ny��l�h�G`��u�)�ܖ��4�-�}���O��Gtsd�;{	�k���,^�����~`����7,M�|C�mB"-�D��wq|�)ї:6�:�8����0�x��}%A�C`��I�4ip=�D�B�蓁)�OZ���}	���st��z�'�q�!d��sm|��&z����^�U��ZNՋ9TeHE�,�5g�X:�h�G׬"R�́'z�������u��k����D+�ƍ��Q`K���2�Zp�wp�'!�	F�< Wԥ0�n�x:�d�w�a��(n@Xa��]8*^���P�xcQ��(+��8�s���(���_����w3&�L��} �{q��i���{B���+�雫�+�?�n�����&�N
Mf�&Z˹G>�>��"�AYĲ�3^
HqE��0�r����9���D*����.fًwB:�nY�eeFץ���M���_Mߐ-���ɥ/i�L�[ξgr�0�i�p�:����_c� o����v�s�-?������,�JZ���K�sVp���<`Wb�܀����p-8�3�M�0�}S��Jl)3!�ޔ��S3�A�N+�@�>�vHo��b�m��e��� ��$:���q�<E�9������l����'$��)���OU8�5p�Z�+����<?Sӊ��U{|�:�nl#ڲw��_���0Qs4����-R��������v9�}����M���◜��]~��WH
O��	 ����`X�����[N�
(�����U�T�I�����S�������.I���J��_ ����(a�0�	WS���[�}�__���&��£X7{���
	�þ��<	��!L����a&��f�h��gmc�/;p�p�q�y�]�Xr[6��9���0��sGu�!���eٽ�/X�]nE����O��c�4x>�{]��{cE��v�ݒ�m�>6���i���r+w�/]T��J�>ͷIM�5e��-�I��7�|f��akǫ�i�_~i�X�2TՐfW�eG�"���{I
�
#ĠLu��Ơ�H,��<��
?�HyTa�0��0���%��T��˜�f�
_��]�b9fs
=^X����x½_��%�@R�jl2�ᆖ�Kj����~����k��Y�� ���l�4B'���x�Ʉ�Q}
pC'+\Ū�#�]�N]�(Zy�{-8���J��,Ul,O�u����A4�,�$Ĝ�߀/�) hg�h�"h�곀��d�^��P~�g #�H�$s	XF70��4����$i�u_�~ä-4N��k��GH������Z_��HS��PjG�u���"<�Db����(���  �!ȿ(��#��'<k� }TV�9_g����!����E ���!�%7�"	&�00dF2#��j����hiӮj��u�G�,k�Z�h]W���Z�wmV����d�$	�������:���d��u�qi����?�Q����I܇����+}�F�K��+})G�K��S��ܙ�M�/���p��Y�{���C��I7��Բ�*�a>hW��H�QM��-��A�W�d�	<+�F��ZU� b��oPEh�6�T��.��	Ӫ��,7 �V(�$��� �CR�T/ ���j�V%K-s��E9I�6,�df�9/�h*�
iXVRi�B�V��h˦�t��P�I9F���Zp��
ʹ��֞�[�՞lX�֢�_�h��W����iQ(D��YV�4m iӦ_�j�U�Y5�ת��h��q�b4Wۮ�T��iYW��BP�e��V˦u1�;e?�l��l�*y�L��V0��6�$�Z4�d�O���m���v��� �K��GĶ}9@��H�E
�^rl���6�EeR����|Y�uJ��6"p�r6���"�#��-��e��"z����D@�����[I߮Z~�bi�+���a��ֵT�6���������l��R��9�}ŵ���YT[׾��G�mӼ�����tY}yF�G5mۨZ��5�ž}e-^�}�ݦuO�}�BN{Ǵ���U���2�_�d? V!�ay ��Q�U�"����u[�u�b�K-SЮ�6Nbǰ�8��_�?�PN��`���9��"�O��{]mv^ڪ#�5�/�����|(^�^$A���$r�YPi�W��|���9h��CQ�[�$�*�¼�3�9�I!D�a9�K�[��/�P]�K��5��ϸr��|y*͋��&�|��i�Z�K�G��şj�_�"�N��B�b�)&����{	;h ���ꉽsb���v�;��_x����i��GF��^��dů�td��YN��z��u��z(K�6ܪ�����V[��n��Vs�����^��M�����Z�$3��Pf �� ��J�����27f�}��B9=�|���K�c�ѕ1�_�i��b�]����j�s�ڙ��r#���V��Q`�|���d��pGp��ȑ�P�5�M��r��������G}���P����7i�S����>n��&k�,����́钷O*��q�)��@��M�1N���ep�\ʕI;{=�5sK�$P&r+6$��w��0��S/�F�*j� ����!	�L$�z��6�y-lɰ���ʐeb�ji��+��Af1l��6�S��%u&v����>�!nB=�b`�v��D���D�I�Ù��(�nl54Y��;������Iع��j�R��*+)gS���w���:�j+R��}�P�	5<]�M<��������>� ĝ"���v��4)��&n�M��Z�,˱��h5�d)�Db�U's����"�����8���cܨCv'KE;k�^�)'}�*o\| S�p����]�մݾ53�R�V�IhO�/���h� Z��`g�_!T�V�OO���ͤ�*Χ�^�I� ��L.!�Q�nB��y8}��d;S�1y�J	fP��6��Lpw�P^[����]�	ڠ�NS]�?�5����U�#�H]J�4s�t�E�X�PZd((���,W�l��M(W�k�h5��z��� �Vk���2�����ƪ,�?�YR�ѐ���/|2����)Y"���0�c��̩�Y��1,?��
.Sy#a��Sݏ��SS`𫨙��"m��7t͢
����dz4�l�@W���mL�Φ�j0Z&�G��Ka��\��X�$[�+��\�����hمp����P%�s9{�G�tPO��7��]�7&_\��~rg@��]f�T[#�p
��*g
�lw��h7�r$9��0�Εy���|�J�l5XF�?���F��&�|�h�^L`H��4�]�xS�"G�Ȕ,9YWrD;����6|vs������l�{�N��Ԏ��dW��_h\�=�!g
�¾����XG�f�[�l�g���9b��3O��k��F��������K�Ԋn��s��/�mpя��g�s5Q�Sַ戲r�J��pp����t Z;F�d�g��s@Y��fo�,3>�Kqw^N�e(Wu�r3Il�A�[��q������^�`����6�D�\TA�����L�'2%,�������A��+�G�>L�aZh��I��G�����V���
/%��I�����佧r���e�$�)fzm⣌����=�Y�"F8�z�$�Z��5�0�i�T��Nԧq�էj�U�&��N��G<jCi��n�P�/Ӝ�GYkɣk�����U�0�|���;�\Z0|�B�߭�9���� /��I����a[`���L� �.�7C���[�6�(\�r��K>�pK��lD#����+�T��ž�	n�L�����,y5<�F%<k�ރ7�2�ҳ#I[��W+>p�s�ܩ�t�냄[z;�*��8�-<9�a��6�-r=�'�����)��ɣw~�x��ҫ���ӫ����-B-8)5�nQ��ë*/Lbha��z�,hkWP2��SPd�[��ޜ��wa���F\=�/��L��Q:6�f��)����Om�)2�S��#���c�П�t�.q�8�q��zg�.�@E�~�p���BH[�ĨQ�s�D���a�p7Q�@�mE��"�F(�����61Ý2�m-�}ۣJ�&WSi�V�\�j&/m�'7=Ya�MTj+,tB��e�	��}�P��By^8���I
��R��m�L�8CugS��M�h��)���R��&��56�bZ)����5�S��ՙZ���/mm"����¶t����&�.�!p+����/3�;��#yT���˳�����p��YZ�PB-Q��?�Ё���X+��GZ��	��Q1�І��]�x@�z,,$@��\LX��>GO����b\a�9�V�]����s�R0� ��ѝR8�^�$X���'m!��ֶ��֌�-�s�?k�������J���c�(?�(Qh��)�V�j=���Ϗ{Z\I1rVV�v��P����@��)�3���W4��@}���8|UjN�Z�l.\>y��ׁk`����(��!Ӝ������,��'�1�[Z4=i��i�?��I*NXxɫ&�U'>���-�ۯ���-0�k�ѣ�ΌKGй�R#T�\����H��n���C�'s�]]���%ơv�+��2��8�(n���撽�����VI!ܙД�^4���0i�'�ӫGcQ1O��$�;����7���\_�],q�&�_}�?^�=��'M�����9~�*D�ρܱf���L-��Xa���A���]�(�b#��تN�j��vM�`��TN�z����"��Ub��$����@ګ�-W ���x�(��Op�C=h����d׃����OȰ�Vu��R1��[|�f���5@��Ƿ眼sԑ�>���)�6��(  Tw�)P��L]��T�ry��&���ը�{�El*�������WZ�� ��
!i�}j�l'Q��aQ&i?п��.!\�(a�^p�M��
L�]~�1["�c(ba�������#�WC��L�B�е5R�ӫ��1i7�B�z1=�^A��L�\�����/���G]��l��6*�wsa͢b��ٵ@	�fu�a�v���<�.������/6Y�]L�1�N>Y�n���C�+��~���c�Ȇ��w1O��I�i�w'�<wd��B�7�HI������׮9��7��v���}�L"}��(�>u��o/�H{H�w�S7ofPХ����^5��{81/�\|o_ }˓o�O۬�GD1�������w@1�2��w���?z���I�+	YZh�d��z@���HD�S"�y��b8������6�>�����3��P�(s�fRd�����Ѣ�&�cZh��0'<�~x/��j�������;�R�m?�ҹ��4��-�Y/�r���M��g���� �g4�<�q�T-\� �ؖ�0N�������C��¥G�ә|��!�S�ڛn+���aHwO�7=G��n�%�@6��4�r��'焼�k�b�]|h��:hԠ-��4z`�c\�/sj�T��"wA�*���b4~�wQe� ���s?_)����%���g�gq϶Q�2N�8�i�9�/<�)�uN����3�Ih���g���bNщ�mu���F�-����ò��F��0�Z5lo7�U���E��U9��~����S3]>CL�δx����g�$97�$W�LhY��x(ph'�1���I.C$۲��XM@z3��-������M7Z����J�'��l�9�q:��I\w}�0��jy淌���+�H���c3y�Kh�3Ht�:WR�8�E��L3�?k�B)x:�E��d6�˦Xݼ���I/��V��54�[�=+W/�Մ6
��|P�5�3�싱����,r�%�rm˝�f�u�,�n�E��S�9y-��H�z
�>C���{޳荴=u��s��<L��w����������������f���G� �)���1�`��16�Җ��h�"��[qv�g\QNp��Ī���Q4H[��{>��|��S��5��t7d�J�F1��mL���&�����q�P�>Mx���&�N��bk9b�����KY[[���Fjn�{�`T�c��!L\WD��ĉ���ޞc�u�څɁ�cS����4�NO��:����Չ��zh\��x��vu+f��������=gC������V>��6ih�����~>}�Ы��2������k��it2	ap�߄��m/ωڑ-�W(�\w��v�u��1�ࠍg�}/��k�,�`H��yYV���v��.{�x՗�sS��+���E 8����G�;7���vc�*fB,}�u�Mh����E`.�x�jb�enbk�u����Y��MS���%)��ez�.���Vl�֊P��C]�r�mfpϚKȿZ�4�2-��]k�v �MJ��^&ov���ˏo��Ybs��j��v��Y�ɥt�iܩ=)]���5���77M����rs焎;d���6��GВ���A����
�<
tO��ܗE��i��:�ޓ�� �4bZD��h�{i�|������ L����~��y�W��-ؒ42���?5S�/!�|8���]���bO���nr/���9SOtCJ��HI�%���k�YU�Kߖ:~��V{9��8��c3r7���4N�i�}�g�O�8~y�<�#�_��ֶ,�̍���ｻ���&3����s��!�ȧKp�^d�������F%�ƺ�@�G�h��y?풯���܅�6�h�BNlc�s(�5�&�,Yy'",!a��ꈏ(O(�>�b��dy���i��fV��V�{���؟��V�Y�t/W\��/G��jT�x�I;9P��ab�K�G5����G���\-���7Z��V�{ǟ��x�]��;I�̑�V��7v��>��d?�T�M�v��E�����0�&#�0P�b˧!>�Wl����d"�	��~��j��Y+�e����P���Tސ���Gr�Y��@�����;�}a��_A�.Ay��}�4VV�����|�>>N�!�+���rxA���."&�b;��uk�d&�Y�81�k�8��sKL.G�Ԕw�%.�+@����e�#6����ٌ����V�K`��5\Y�?�tC��i��V��L5 "���V����$Z��g.Y2��0��g4ZB��V�^�Ve�B�0�iI��Y�ʱ+Beh����$�=)�q��n�\zVG�`e�#g�ְ��ƽ�'i��ϐ����7qEIo0`z��� w��R�wF�.�Q����*�������^+?�Yk7��X����ZᏃ����O�q�n��KI�WEOF�-ڔ��T�Te�q��e��u�܊qQ��ᖾ�`j݅f[8�׋e�3���_nԇY�c�EUXv��k=`nҗ�P���%(Yύ�*�sϔ�|�Y�`l�/z>Qv�	\bA��� ��M,��T��_�h�Bb�3�I�;c�G7���s�b���m�h�Yڍ�]z�;��{V�^��2}X�
"������]�bY�{���ҭ�_`�"kD�Gh���{}p�Zc��\�bj�����3zj�r���{Oo�>�h���/#sW�诮KNn�RS,�^��I���UQg���������U��ֲ�uHq�,m[�j�v�`���`�R5i5�MUNT�}|w����@Թ���UM�� N·������^c�`�v��QW�_�
���T����@'��:�G7��	��,�I��Q����/�����A�鍵+�:G��2|��~C*�q��O�E��Wg���q��:F���I���b���1Z���a̸��4���(�x��E�&�gџ{�}��;*��7[�:���R(��C��8l%�-�9���]pXR}m�-���<�A�}a���\`v0���Ks�^��p��Q��^B��=Vq=:������=P��V�&bb㓂a@C��mG��a�/g]f�E�#�)��	O�	Nĭ��Zq������Ux��/C���L\���_���7+��K�_ͻް��]p��i�#օ�:8�񶌺`����Rr���u`���ua��pK(�t�Bq�x�a�nr/��3]#�d�x0��1��9s��M��h�h޴�r��9���hl��@��kP��&��ɹ��m])������V������0��赞���gp�{�Q����2lJ�9�uS�Y|�fn
B������9��՗_����tL\��P��x`��A�l�����`��"�$<����!��q7e��O���=���.1z��OD��������z��a�OLcg�C�D������0��kzG�Q�G>���F3�1P{��EC5�N�ʉ�͜*N1���p�{Ŕ�zf�D1¥��J�`��~�c ����0@�t�]��sm�P\LDE�Nو*^�Ϯ@:�]�oF%������NqC�`

ք��eL�J-����;����~�*�_`~Eb����BQ�������~��@b�6�HwÕ͌�c��w,\`v��Ɏ��y: Y2���:F��|�j�0n�!���^q��+�dt����M�r�i}�͍�.7�F�"����x�j2`.�2yW�~=�>A�	��|������1�ѡ>�A��r���HF��� ]2��G�6Ɨ5�8 o�q�Y �cO����C��e�)Sc{Ѽ���G>헼�1M*6tq!#y�  �ӧ�sx5"��bc\�H�)H�Ma<MݿV�<��U�_-W7Q�~�$vU
��y�����S�}����L��x�3'��~;\'�E�w'�^iQh�YR�U��p)�݉{�S �0� �2������'��"��	��DA�k�+\��2��H�Yƽ�vV�eq�[���郾��a��%k�g�E���SqY_H$��M�g�ʝ�;��x}a�I�z��鮎�[z�����K)�oO����Tp�eA56���\���#��+�hE��w4��~%���ء+����;`�89�wnO[P���߆�yؿ�>�*�����\��G�ޯT��4�:� ��N�d��^w�� � �g��e���S�D�@�d`������g԰�=�u���O2�>}�FM�Y�5�``�`�{b�L�
Z��wզ��]#&�����-��M�\��i{a�IC�5��|T�q������N�}��-l~@j���������
�e|4�p$e�N4p�)듼{����D��P����O|�jՕ2�)�P9�mv{@ꆴ|s鉭9M�qA��䋉{���U;���^��A7���kкy�B�f����t��EW������4%~<��h|�3��-���=�RH=�ͧNǆt����g��N��<.��Z�`/�Wp���\��F܌��⺠��"4j0̷�l�F|�r%D�iۛ��L���1-v�C�9"�t{6���M�_�a�XB�\�j,=�)Bz!���;r�0 `B�/:E|��a�p�+�`l[���H���~V6��;��dix#�����p7�:�h�ƅ(F�#�@����-���k_�޽q�g���;"E��.4��G���J@��(���y�Y�o:�E_�[��ϭ����n����3�F+�[�g1��b�O[�g���w>[�7�R�Y�����2�&�"z�]�=�d��O\��^�㎙c��lĸ��=��-�#�6;�jq%�R�5��#tUk�X��TK���%=��(~��C��ؐ�d������"]�>�h�\����{ګP��Š̾xF���>�kr�c������D����ՙF���g%|�I�<�\�����u��uÐ�����!��E��_K��,��U�r ���0�L�Ks�0Cf�/�e1: ���i���z�dj��ٰɉv����������f�>㥺̷ڲ�-B�F~-=-uT������F��؟�;����!B�z�w�	�]P��� �����C˿�����J��~G��A ���l.�z�����|����	�3VXE�K�W�0���`�-������?|���F�7�v�4p��c��ɩ�Hg
>�ޞƕ�Z�W��SB�m5�k9��5dwv�;�]���}�Ћ^�{^����`{��D5�u��T|�l�G1������:���#9xC�_
n(l�,j|(�|��
?<�Dh�x��Y�s�%/�5/�5��֨�U����7gZ��RgZ�5�Z��Y�0Y˃CQ�����ŒB|lX��MT�'0#���\�/¸�xWi��#�����BL�dVܼ��laE2g�}����c��zd'�ݨy�7���g�0�IG�bȪ�lYc�"'�n��wx�^�H����By��O@}(��<`�g����Ґ��'��揭�������z'4~ك���O���]F���q�������Ss�@�J�>�Xq�+<�g[q�K�y/��(�ξVU�'|0�}��f0_ ���^�}5x�U��ȟ~�Н�?��T��=��_4��{q�J�?J���&�Wן�?�~U�F�/��_v%�����>�?9�S���F�����]����I�� �V�w\�b�BZؗa�iW�=Ԫ��W��vd[�7��8�x���=[�ݢ�k�w��^x���)�����ނ�οFi���ֺ�V���Y�Wx�	���i��Wd}+���i]��}�W������ӫ��W��F�v��^��ͽp���
�e\9����U�v6���,���cDt���������g�]r�j�����P���?4-۔�DɠG�;�It|�u<�P����Gő��;\j��EJZ��[?��~��@J�v<]��kf�@,��g�9w��8X|g��:�]��0�1�/�)oE��{���-1+��
�ש��,��̜Ě���3����<?U!
�7N8o���8��YAzOp�	��]A1Ǚ� �י0|ӻ���m"X�p�s�{���A��o{�2ă���ni(�>E�y����݄�P���XK��/WB�j��ҡ�P�?a�[؋��B	�B	�(A��(���=�"P�xh�y��#����{�z}��o�o<_3�p	3y��5�>gP�.'�)�v�?���&��ɭ����s�hC�(���=J$�[zE�sc��a��.���Z�g)��36�)�t�������r��)�e�/Gh.$3tM|%���P;yY�'�\���:rh&���|�ޝ�|\�{��a�]�6��l����z����ow��s~Q���-�୸c� ��,e��x�/)���4�rD�FZb��T���J��`(")�_�P\n��? ~�������Ɯ��B �z�}��u������`ɻl�k�nKCq9q�-JnE�)*�d����%!Kɮ,.(�0N"d����O��4��yo3O���S��&��f�UrN����yF�Y)3NKnĠ�+"MO$x(2�`}��Ҩa�2Xdk�:���I;X�^1烙��_cj~B�{�F���KMu&�s�m��^B�
B>��T_�*h��_�cs����oX�R7�)K���b?S�
�2�w�x�:%t��X9�l�כ�k�t����� �������f�J؟�k�:Ú�Dk�"N�C�^S���/�%WJ4�8�B�RCe6��s���VN@Vh�F�)�"qft 
�&����n�O���1������8>�e�M
$��B�����]�[9\�)��!���t+}�G����#�zΒ�@.$oW�:�u(H���x�����j���aI1�Fʼ1��"��a~�C� g�G\za��".-��Px������t��l�d*��l���>��d�}F���&�_�`j�5�/�%�B���&L���!du�~�G�K${ʷ	gpU���t�%k��S��Zob����g�����+��u�a,��=�2� 잫�7����x��!�"h�}^>���au�?J�uk��  �A�����mj�lx�WZ۪1|K/"b��`�=b!A���T�xo�����af�v��j�Z����6��c�KQD�j!��T�)��H����	��I�L�^E���Wm��j�,��U���Vl}�>QQl���Ul-��3yMB��߿kݵ�]���9��g���O��9pڿG�V�6ߛu��6��8�Q�X����M--���S�%�]���g^r\�|{b^Ek��KU�&t��b×G?��%�p/�\�c٩u��o?��W�����C�*}�w_Ք��훶�S�=ڪh�R���qLT����۲���N�b����M:uRZtiOY���-1!-�6���zhJ�3��3ƕ��6�L�Ԥ³��y!}��/�9�q��;Q�!��nm�oљ9YgW]�ry�f���Dy)�[7G��~R���)�<�2�À�cw��ԍ_����ɫ����[�6���׺|�A��Os����@���ￒL6�y�������uκM�Q;_����f�.x��C�#�,�����A�wn,,S��������<�=�r\�w�_�膯��s�'F׿^�\}��b�ȃ-O��������W=8j�����#�Պ�����:�Ѐ���֋��v�^)o3�Xd�⾑�=�t�hcB��򓣃�U���I���tMu:ͣ��{o��ƌ��#$���r�${������zѭN�6(���|���u�o���GŻ��7F�T�K�G�D\�M����y��n�6��[î�7����{ɑt�)����쵎��'^��?gފZ�˔c}��yDw���t�6qs���.ra���J����~A�;W�����ؓ;���j��)C�~V}����51������N���O�1���kKb~U���+��i���F��[c���|���'�2Z���54�K�nWw��]N�PR�6g���n{B��'3�C�$�%�׺?��� z�Ĕ�K7���ׅ{U�ߔ��L���b�~~NY!��ÿ�9�zV��A+�y���{8#|�� �Ƈ3G�]�h��݄!�w���=����ʆ�n�?�t��E�n�}T���[�㦥�+"fL޲͏��uY�^B�[®���Ꝕ\�T1��t٢���j���~O.w���<N4'���s�b��s���;�)�oy���到��eG�~�#<agZݞٚEB�$�6C�3{_�N�揫�{h���õ�p�3����}6o���X1�R�1��~ú-ܒ�]�k��?z�ܽ�{�ORI����� u]��F��[Im�"�ny<3�������F�fӧc=�<�o�8oxn�������Kz���7��~e��V���n�c���}\�����R���?���u��W��66:d_8'^�9<�~K���84r���5RWg�&�WU6׾�r4g�ѥ]/�������B�8^d���%Tݬ�Ҕ�յ��Jw6%��;�Z��Ԓ���)�rua��M�����κ-)uT-�e��s����|"�s��uAQ눲�
�&�|��Ot�fs��~R��������eD�43nEm��~�.�]wv+&��/7�{t���ޙ7�����dd�������_so��W�w*�+�^��B�������BθD��$yKp�bͫ5ג��D?�6�xs~���E���nô�!��,�W���K��k��>�>��x�˱ç���جx|%v��'�-�4u�0w���9e.s��M�1yxhrĥ��]���M%s�y	�Η�y��y�U��Щ�~����ٸ�����nU��U����h�-�.�Gl�����Ry�!��W����cn�_쾳��5Y)9_��}��M�;�==���+o*���(��������w?x�Q��ut���l�u|���L���޵$�f����UKI�ϐSS$��	��QJB[�s�}�hW�j.JG�,U_7���z�Y�prl��:��a�9�����\o�O��9�R�d"`fw��g;��kh���\@t��1N���]��� t���X:Ak�L{Ht6������]��hlcM��DG�s���Y`t{��m�G˷����|�ww4��ѧ��jk��k�=+$���b��ZO8���,��^���������ޱ/��v\|�;[ܯ;ZZ~+��~u��r���,-/�|�/OZ�s��A�}�^��o��ܽ����3_f�o�ϭx-�+�y���5>�`�Ŀ;�e�hk|n���_<�e���d�N�wO��x彐)b���d�gdy":�ᯕ (a���U*fߋ���Wx%v���������šCB�@��� Z��5����ͳ��U�����dz�/���
���<�& $�*�&Մ'�Xb�4�/O�g�ނTRD��Q�4D �iH5����\"^ `�U ^�F�C0H�+P�RE�@A*	�� ����T9���K�)� �����C���@Rr0y�ҏkUΐ2hAI�a�@�
��o8���RpJ�� �&d��$�������gP���� �Q� �l�Pg;�)MT J�����Z�ґrB�ZG�3;�N�����c���PQ��
��,���1�J��h�1b"�Q�hp3	���������<
���/}K"1I:jLz\|vЄ�<?� �"9�?HW�b�5��!��g�İ̔Qi��R��GƧJR�x�'��%�g�O��$I�j��'��\��0����n W�	J>I	���J14f���{�0�?��6����Y> z�F�(&i���fr7�6��j ,��PǊZ��Q/��0#!Y�
�$J��K�k��{�L�5��P ��A(i3SI��l���&k��3�����֡ ������P{p�ȷ�}�0�3.��l�	 N�U�)cf�>�	*��%@NX��x\t�������D�y��hn�Qδ���c��R�݈[L2@����� 54pM�� �R�� .�9��pt�RK`Z��L")���◊Å�15&A3�x<�������j�%up8�2\��3L����b���?f�y�0v�>1`�<E(�g���5���{��}0�J��c�#/9he ��B��)i�lv��U�B��Q�s��3��g���)��0L��I��Q��l��v#�\n�M�w�YCD"�Y(F?���@X��	5I0�+����P����ЁCP�n�T�����ڷS�9�or�q�b�������~�}nw�R� ~�����'}@�x�G�RZ��i�`J�~\:B�A@���*1zG�13'�BgE��#g2��"�E�gD���	�~������p`v� ��JWDN��g|�X�J�lh3Z��Zd���]��P��MlU �B&���T��aa�'��@��p)���QpU�
�0�'3;f� W�	Lx��J��C�5�W���F�5��� �l��!�yp\�pc�Ѡ@,���)�qk3�k�9���*pi`�6)f�EJ�m�yQO�R���4"�[�*�F�gC���d�5���Mi6L6kg��BB�_B0�:ܬ�v̩�,G���L��B�M�\�I�?C��ʱ�m�,����!����;�M��Uw4
V�RQ�M��:�(&�fm�� BXA@���K�J�@�J�S�Q��#�cRְ� �t>�R�x�"���?#�͓�`�'�JQ�T�\���4����t����!��A�(�L]h�	�w���B��p�N��h�`���]r6�a��L�|U67�٤fQ���~/���I���n��,t8&�t-�	6X�Zn�<�+L5ʎpG*#9�+I��y�-50��a!0�~Q�%`�m0����=��B�կ!h5����s"�\�m"`����U�P�4ؗ��h�' �}��pj?�PJ�w��Vn`GM�'�+6�
��)�i� ��9��hh���;֝�h��!�d"��=�
���0���.v��]�b���.v��]�b���.v��]�b���.v��]��7��@�3U �  