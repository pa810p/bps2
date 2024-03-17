import * as React from 'react';
import AppBar from '@mui/material/AppBar';
import Box from '@mui/material/Box';
import Toolbar from '@mui/material/Toolbar';
import IconButton from '@mui/material/IconButton';
import Typography from '@mui/material/Typography';
import Menu from '@mui/material/Menu';
import MenuIcon from '@mui/icons-material/Menu';
import Container from '@mui/material/Container';
// import Avatar from '@mui/material/Avatar';
import Button from '@mui/material/Button';
import Tooltip from '@mui/material/Tooltip';
import MenuItem from '@mui/material/MenuItem';
import i18n from "i18next";
import { useTranslation, initReactI18next } from "react-i18next";
import PopupState, { bindTrigger, bindMenu } from 'material-ui-popup-state';
import { useNavigate } from "react-router-dom";


import { Link } from 'react-router-dom';
import { SvgIcon } from "@mui/material";


import { ReactComponent as FlagPL } from './pl.svg';
import { ReactComponent as FlagGB } from './gb.svg';
import { ReactComponent as FlagDE } from './de.svg';
import { ReactComponent as FlagEU } from './eu.svg';
import { ReactComponent as IconSmile} from './smile.svg';

let localeFlag = <FlagEU />

const pages = ['Home'];
const settings = ['Graphs', 'Units', 'Dashboard'];

function setLanguage(lang: string) {
    console.log('Language: ' + lang)
    switch (lang) {
        case 'GB': localeFlag = <FlagGB />;
            i18n.changeLanguage('gb')
            break;
        case 'DE': localeFlag = <FlagDE />;
            i18n.changeLanguage('de')
            break;
        case 'PL': localeFlag = <FlagPL />;
            i18n.changeLanguage('pl')
            break;
        default: localeFlag = <FlagEU />
    }
}

i18n
    .use(initReactI18next) // passes i18n down to react-i18next
    .init({
        resources: {
            gb: {
                translation: {
                    "pressure": "Pressure",
                    "sugar": "Sugar",
                }
            },
            pl: {
                translation: {
                    "pressure": "Ciśnienie",
                    "sugar": "Cukier",
                }
            },
            de: {
                translation: {
                    "pressure": "Druck",
                    "sugar": "Zucker",
                }
            }
        },
        lng: "gb", // if you're using a language detector, do not define the lng option
        fallbackLng: "gb",

        interpolation: {
            escapeValue: false // react already safes from xss => https://www.i18next.com/translation-function/interpolation#unescape
        }
    });

export const RenderBloodNavBar = () => {
    console.log("renderBloodNavBar")
    const { t } = useTranslation('translation')
    const navigate = useNavigate();

    const [anchorElNav, setAnchorElNav] = React.useState<null | HTMLElement>(null);
    const [anchorElUser, setAnchorElUser] = React.useState<null | HTMLElement>(null);

    const handleOpenNavMenu = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorElNav(event.currentTarget);
    };
    const handleOpenUserMenu = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorElUser(event.currentTarget);
    };

    const handleCloseNavMenu = () => {
        console.log('handleCloseNavMenu')
        setAnchorElNav(null);
    };

    const handleCloseUserMenu = () => {
        setAnchorElUser(null);
    };

    const handleBack = () => {
        console.log('back pressed');
    }

    const handleBPS2Click = () => {
        navigate('/');
        setAnchorElNav(null);
    }

    const handlePressureClick = () => {
        navigate('/pressure');
        setAnchorElNav(null);
    }

    const handleSugarClick = () => {
        navigate('/sugar');
        setAnchorElNav(null);
    }

    const handleUrineAcidClick = () => {
        navigate('/urine_acid');
        setAnchorElNav(null);
    }

    const handleCholesterolClick = () => {
        navigate('/cholesterol');
        setAnchorElNav(null);
    }

    const handleChartsClick = () => {
        navigate('/')
        setAnchorElNav(null);
    }

    return (
        <AppBar position="static">
            <Container maxWidth="xl">
                <Toolbar disableGutters>
                    {/*
                    <Typography
                        variant="h6"
                        noWrap
                        component="div" // component="a" href="#app-bar-with-responsive-menu"
                        sx={{ mr: 2, display: { xs: 'none', md: 'none' } }} //, fontFamily: 'monospace', fontWeight: 700, letterSpacing: '.3rem', color: 'inherit', textDecoration: 'none',}}
                    >
                        LOGO
                    </Typography>
                    */}
                    <Box sx={{ flexGrow: 0, display: { xs: 'flex', md: 'flex' } }}>
                        <Button onClick={handleBack}>
                             <Typography textAlign="left">
                                 &lt;
                             </Typography>
                        </Button>
                        <IconButton
                            size="large"
                            aria-label="account of current user"
                            aria-controls="menu-appbar"
                            aria-haspopup="true"
                            onClick={handleOpenNavMenu}
                            color="inherit"
                        >
                            <MenuIcon />
                        </IconButton>
                        <Menu
                            id="menu-appbar"
                            anchorEl={anchorElNav}
                            anchorOrigin={{
                                vertical: 'bottom',
                                horizontal: 'left',
                            }}
                            keepMounted
                            transformOrigin={{
                                vertical: 'top',
                                horizontal: 'left',
                            }}
                            open={Boolean(anchorElNav)}
                            onClose={handleCloseNavMenu}
                            sx={{
                                display: { xs: 'block', md: 'flex' },
                            }}
                        >

                            <MenuItem onClick={handleBPS2Click}>
                                <Typography textAlign="center">
                                    <Link style={{ textDecoration: "none", color: "white" }} to="/">{t("BPS2")}</Link>
                                </Typography>
                            </MenuItem>
                            <MenuItem onClick={handlePressureClick}>
                                <Typography textAlign="center">
                                    <Link style={{ textDecoration: "none", color: "white" }} to="pressure">{t("pressure")}</Link>
                                </Typography>
                            </MenuItem>
                            <MenuItem onClick={handleSugarClick}>
                                <Typography textAlign="center">
                                    <Link style={{ textDecoration: "none", color: "white" }} to="sugar">{t("sugar")}</Link>
                                </Typography>
                            </MenuItem>
                            <MenuItem onClick={handleUrineAcidClick}>
                                <Typography textAlign="center">
                                    <Link style={{ textDecoration: "none", color: "white" }} to="urine_acid">{t("urine acid")}</Link>
                                </Typography>
                            </MenuItem>
                            <MenuItem onClick={handleCholesterolClick}>
                                 <Typography textAlign="center">
                                     <Link style={{ textDecoration: "none", color: "white" }} to="cholesterol">{t("cholesterol")}</Link>
                                 </Typography>
                             </MenuItem>
                             <MenuItem onClick={handleChartsClick}>
                                <Typography textAlign="center">
                                     <Link style={{ textDecoration: "none", color: "white" }} to="charts">{t("charts")}</Link>
                                 </Typography>
                             </MenuItem>

                            {/*pages.map((page) => (
                                <MenuItem key={page} onClick={handleCloseNavMenu}>
                                    <Typography textAlign="center">
                                        <Link style={{ textDecoration: "none", color: "white" }} to="{page}">{page}</Link>
                                    </Typography>
                                </MenuItem>
                            ))*/}
                        </Menu>
                    </Box>
                    {/* {pages.map((page) => ( */}
                    <MenuItem>  {/* onClick={handleCloseNavMenu} */}
                        <Typography textAlign="center">
                            <Link style={{ textDecoration: "none", color: "white" }} to="pressure">{t("pressure")}</Link>
                        </Typography>
                    </MenuItem>
                    <MenuItem>
                        <Typography textAlign="center">
                            <Link style={{ textDecoration: "none", color: "white" }} to="sugar">{t("sugar")}</Link>
                        </Typography>
                    </MenuItem>
                    {/*
                    <Box sx={{ flexGrow: 1, display: { xs: 'none', md: 'flex' } }}>
                        {pages.map((page) => (
                            <Button
                                key={page}
                                onClick={handleCloseNavMenu}
                                sx={{ my: 2, color: 'white', display: 'block' }}
                            >
                                <Link style={{ textDecoration: "none", color: "white" }} to="/${page}">{page}</Link>
                            </Button>
                        ))}
                    </Box>
                        */}
                    <Box sx={{ flexGrow: 1, display: { xs: 'flex', md: 'flex' } }} />
                    <Box>
                        <PopupState variant="popover" popupId="demo-popup-menu">
                            {(popupState) => (
                                <React.Fragment>
                                    <Button variant="contained" {...bindTrigger(popupState)}><SvgIcon>{localeFlag}</SvgIcon></Button>
                                    <Menu {...bindMenu(popupState)}>
                                        <MenuItem onClick={() => {
                                            setLanguage('GB')
                                            popupState.close()
                                        }
                                        }>
                                            <SvgIcon><FlagGB /></SvgIcon></MenuItem>
                                        <MenuItem onClick={() => {
                                            setLanguage('DE')
                                            popupState.close()
                                        }
                                        }>
                                            <SvgIcon><FlagDE /></SvgIcon></MenuItem>
                                        <MenuItem onClick={() => {
                                            setLanguage('PL')
                                            popupState.close()
                                        }
                                        }>
                                            <SvgIcon><FlagPL /></SvgIcon></MenuItem>
                                    </Menu>
                                </React.Fragment>
                            )}
                        </PopupState>
                    </Box>
                    <Box sx={{ flexGrow: 0 }}>
                        <Tooltip title="Placeholder for options.">
                            <IconButton onClick={handleOpenUserMenu} sx={{ p: 0 }}>
                                <SvgIcon><IconSmile /></SvgIcon>
                            </IconButton>
                        </Tooltip>
                        <Menu
                            sx={{ mt: '45px' }}
                            id="menu-appbar"
                            anchorEl={anchorElUser}
                            anchorOrigin={{
                                vertical: 'top',
                                horizontal: 'right',
                            }}
                            keepMounted
                            transformOrigin={{
                                vertical: 'top',
                                horizontal: 'right',
                            }}
                            open={Boolean(anchorElUser)}
                            onClose={handleCloseUserMenu}
                        >
                            {settings.map((setting) => (
                                <MenuItem key={setting} onClick={handleCloseUserMenu}>
                                    <Typography textAlign="center">{setting}</Typography>
                                </MenuItem>
                            ))}
                        </Menu>
                    </Box>
                </Toolbar>
            </Container>
        </AppBar>
    );
}
